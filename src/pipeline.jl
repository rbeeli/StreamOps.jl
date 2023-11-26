"""
    @pipeline op1 op2 ...

Constructs a chained operation pipeline, where each operation
is a subtype of `Op`. The operation pipeline is type-stable
due to the chaining of operations at compile-time, i.e.
the last operation is passed to the constructor of the
second last operation, and so on.

The constructor is called with setting the `next` named argument
to the succeeding operation.

Example
=======

    pipe = @pipeline OpFunc(x -> abs(x)^2) OpLag{Float64}(1) OpPrint()

is the same as manually constructing the pipeline as follows:

    pipe = OpFunc(x -> abs(x)^2; next=OpLag{Float64}(1; next=OpPrint()))


Multi-line syntax using a begin-end block is supported:

    pipe = @pipeline begin
        OpFunc(x -> abs(x)^2)
        OpLag{Float64}(1)
        OpPrint()
    end

"""
macro pipeline(ops...)
    # if arguments are passed inside a block, extract them
    if ops isa Tuple && ops[1].head == :block
        # it's a begin/end block, unwrap contents,
        # filter out LineNumberNode
        ops = filter(e -> !isa(e, LineNumberNode), ops[1].args)
    end

    # start with the last operation (which must specify its 'next' argument or use default)
    pipeline_expr = ops[end]
    if isa(pipeline_expr, Symbol)
        # escape if symbol (variable)
        pipeline_expr = esc(pipeline_expr)
    end

    # iterate in reverse order, wrapping each operation around the succeeding one
    # by setting the 'next' named argument to the succeeding operation.
    # also escape all arguments so variable scope is preserved.
    for i in length(ops):-1:1
        op = ops[i]
        is_pipeline_end = i == length(ops)

        if !is_pipeline_end && (!(op isa Expr) || op.head != :call)
            error("@pipeline expects instance creation expressions like OpReturn(), OpPrint(), etc., but got: $op")
        end

        if op isa Expr
            next_set = false
            for i in 2:length(op.args) # skip first argument (operation name)
                arg = op.args[i]

                if isa(arg, Expr) && arg.head == :parameters
                    for kwarg in arg.args
                        if isa(kwarg, Expr) && kwarg.head == :kw
                            # escape keyword argument values
                            kwarg.args[2] = esc(kwarg.args[2])

                            # check if 'next' argument is already set
                            if !is_pipeline_end && kwarg.args[1] == :next
                                error("Keyword argument 'next' already set for intermediate operation: $op")
                            end
                        end
                    end
                    if !next_set && !is_pipeline_end
                        push!(arg.args, Expr(:kw, :next, pipeline_expr))
                        next_set = true
                    end
                elseif isa(arg, Symbol) || (isa(arg, Expr) && arg.head != :kw)
                    # escape symbols and non-keyword expressions
                    op.args[i] = esc(arg)
                    for kwarg in arg.args
                        if isa(kwarg, Expr) && kwarg.head == :kw
                            # escape keyword argument values
                            kwarg.args[2] = esc(kwarg.args[2])
                        end
                    end
                end
            end

            if !next_set && !is_pipeline_end
                # insert named parameters block with chained operation before lambda or other args
                insert!(op.args, 2, Expr(:parameters, Expr(:kw, :next, pipeline_expr)))
            end
        end

        # update pipeline expression
        !is_pipeline_end && (pipeline_expr = op)
    end

    pipeline_expr
end
