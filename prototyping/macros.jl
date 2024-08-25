"""
Forwards the current value to all operations defined
in the block of the `@broadcast_collect` call.
The return value of each pipeline is collected and returned as a tuple.

There exist two modes:

- `:broadcast` (default)

    Each pipeline within the `@broadcast_collect` block
    receives the same input value.

- `:sequential`

    Each pipeline within the `@broadcast_collect` block
    receives the output of the previous pipeline as input.

"""
macro broadcast_collect(ops...)
    ops
end

"""
Forwards the current value to all operations defined
in the block of the `@broadcast` call.

This operation does not return any value, but instead
forwards the input value to the downstream pipeline.

Each pipeline within the `@broadcast` block receives the same input value.
"""
macro broadcast(ops...)
    ops
end

"""
Only keeps values that meet the condition.
Otherwise, returns `nothing` if the condition is not met.
"""
macro filter(condition)
    condition
end

"""
Skips values that meet the condition (opposite of `@filter`).
Returns `nothing` if the condition is met.
"""
macro skip_if(condition)
    condition
end

# filter line number nodes in block expressions
filter_ops(ops) = filter(x -> !isa(x, LineNumberNode), ops)

function make_op(
    op,
    op_var_prev,
    op_vars_all,
    state_inits,
    block
)
    if op isa Symbol || op.head == :escape
        state_var = gensym("state")
        push!(state_inits, :(
            local $(state_var) = $(esc(op))
        ))
        push!(op_vars_all, gensym("op"))
        push!(block.args, :(local $(op_vars_all[end]) = ($(state_var))($(op_var_prev))))
    elseif  op.head == :call
        if op.args[1] == Symbol("|>")
            # operations chained using |> behave like a block (sequential)
            op_block = make_recursive(
                op.args[2:end],
                op_var_prev,
                op_vars_all,
                state_inits;
                mode=:sequential
            )
            push!(op_vars_all, gensym("|>"))
            push!(block.args, :(local $(op_vars_all[end]) = $(op_block)))
        else
            # other call, just use it as is
            state_var = gensym("state")
            push!(state_inits, :(
                local $(state_var) = $(esc(op))
            ))
            push!(op_vars_all, gensym("call"))
            push!(block.args, :(local $(op_vars_all[end]) = ($(state_var))($(op_var_prev))))
        end
    elseif op.head == :block
        op_block = make_recursive(
            op.args,
            op_var_prev,
            op_vars_all,
            state_inits;
            mode=:sequential
        )
        push!(op_vars_all, gensym("block"))
        push!(block.args, :(local $(op_vars_all[end]) = $(op_block)))
    elseif op.head == :macrocall
        length(op.args) > 0 || error("Macro call without arguments: $op")

        if op.args[1] == Symbol("@broadcast_collect")
            # --------------
            # @broadcast_collect
            # --------------
            t_exprs = macroexpand(@__MODULE__, op, recursive=false)
            t_exprs_filtered = []

            mode = :broadcast
            valid_modes = [:sequential, :broadcast]
            for expr in t_exprs
                if expr isa Expr && expr.head == Symbol("=") && expr.args[1] == :mode && expr.args[2] isa QuoteNode
                    # collection mode
                    mode = expr.args[2].value
                    mode in valid_modes || error("Invalid @broadcast_collect mode: $mode")
                else
                    push!(t_exprs_filtered, expr)
                end
            end

            if length(t_exprs_filtered) == 1
                t_exprs_filtered = t_exprs_filtered[1]
            end

            # unwrap Tuple{Expr}
            if t_exprs_filtered isa Tuple{Expr}
                t_exprs_filtered = t_exprs_filtered[1]
            end

            # unwrap block
            if t_exprs_filtered isa Expr && t_exprs_filtered.head == :block
                t_exprs_filtered = t_exprs_filtered.args
            end

            t_block = make_recursive(
                t_exprs_filtered,
                op_var_prev,
                op_vars_all,
                state_inits;
                mode=mode
            )
            
            # create tuple from op vars and add to block
            tuple_args = map(x -> x.args[1].args[1], t_block.args)
            tuple_expr = Expr(:tuple, tuple_args...)
            push!(t_block.args, tuple_expr)

            # store block result in variable
            push!(op_vars_all, gensym("broadcast_collect"))
            push!(block.args, :(
                local $(op_vars_all[end]) = $(t_block)
            ))
        elseif op.args[1] == Symbol("@broadcast")
            # --------------
            # @broadcast
            # --------------
            b_exprs = macroexpand(@__MODULE__, op, recursive=false)

            # unwrap Tuple{Expr}
            if b_exprs isa Tuple{Expr}
                b_exprs = b_exprs[1]
            end

            # unwrap block
            if b_exprs isa Expr && b_exprs.head == :block
                b_exprs = b_exprs.args
            end

            b_block = make_recursive(
                b_exprs,
                op_var_prev,
                op_vars_all,
                state_inits;
                mode=:broadcast
            )

            # add broadcast block and pass on original input value
            push!(op_vars_all, gensym("broadcast"))
            push!(block.args, :(
                local $(op_vars_all[end]) = begin
                    $(b_block)
                    $(op_var_prev) # pass on input value of broadcast
                end
            ))
        elseif op.args[1] == Symbol("@filter")
            # --------------
            # @filter
            # --------------
            if_expr = macroexpand(@__MODULE__, op, recursive=true)
            if_var = gensym("filter_fn")
            push!(block.args, :(
                begin
                    local $(if_var) = $(esc(if_expr))
                    ($(if_var)($(op_var_prev))) || return nothing
                    $(op_var_prev)
                end
            ))
        elseif op.args[1] == Symbol("@skip_if")
            # --------------
            # @skip_if
            # --------------
            if_expr = macroexpand(@__MODULE__, op, recursive=true)
            if_var = gensym("skip_if")
            push!(block.args, :(
                begin
                    local $(if_var) = $(esc(if_expr))
                    !($(if_var)($(op_var_prev))) || return nothing
                    $(op_var_prev)
                end
            ))
        else
            error("Unknown macro call: $op")
        end
    else
        dump(op; maxdepth=30)
        error("Unkown operation: $op")
    end

    nothing
end

function expr_to_ops(expr)
    # convert multiple tuple expressions to array
    if expr isa Tuple
        expr = collect(expr)
    end

    if !(expr isa AbstractArray)
        expr = [expr]
    end

    expr = filter_ops(expr)
end

function make_recursive(
    ops,
    op_var_prev,
    op_vars_all,
    state_inits;
    mode=:sequential # :sequential or :broadcast
)
    ops = expr_to_ops(ops)
    block = Expr(:block)

    if mode == :sequential
        for op in ops
            make_op(
                op,
                op_var_prev,
                op_vars_all,
                state_inits,
                block
            )
            op_var_prev = op_vars_all[end]
        end
    elseif mode == :broadcast
        for op in ops
            make_op(
                op,
                op_var_prev,
                op_vars_all,
                state_inits,
                block
            )
        end
    else
        error("Unknown mode: $mode")
    end

    block
end

"""
    @streamops op1 op2 ...

    @streamops begin
        op1
        op2
        ...
    end

Constructs a pipeline consisting of arbitrary operations chained together.
The pipeline is constructed using meta-programming. If correctly used,
the resulting code is type-stable and efficient.

Example
=======

    pipe = @streamops Transform(x -> abs(x)^2) Lag{Float64}(1) Print()

Multi-line syntax using a `begin`-`end` block is supported:

    pipe = @streamops begin
        Transform(x -> abs(x)^2)
        Lag{Float64}(1)
        Print()
    end

"""
macro streamops(ops...)
    state_inits = Expr[]
    op_vars_all = Symbol[:x]
    op_var_prev = op_vars_all[end]

    block = make_recursive(
        ops,
        op_var_prev,
        op_vars_all,
        state_inits
    )

    quote
        $(state_inits...)
        function (x::T) where {T}
            $block
        end
    end
end
