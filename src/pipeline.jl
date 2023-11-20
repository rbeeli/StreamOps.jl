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

"""
macro pipeline(ops...)
    # start with the last operation (which must specify its 'next' argument or use default)
    pipeline_expr = ops[end]

    # escape variable if symbol
    if isa(pipeline_expr, Symbol)
        pipeline_expr = :($(esc(pipeline_expr)))
    end

    # iterate in reverse order, wrapping each operation around the succeeding one
    # by setting the 'next' named argument to the succeeding operation
    for op in reverse(ops[1:end-1])
        if !(op isa Expr) || op.head != :call
            error("@pipeline expects instance creation expressions like OpReturn(), OpPrint(), etc., but got: $op")
        end

        next_set = false
        for arg in op.args[2:end]
            if isa(arg, Expr) && arg.head == :parameters
                for kwarg in arg.args
                    if isa(kwarg, Expr) && kwarg.head == :kw && kwarg.args[1] == :next
                        throw(ErrorException("Keyword argument 'next' already set in operation: $op"))
                    end
                end

                # Append 'next=OpX' to parameters block
                push!(arg.args, Expr(:kw, :next, pipeline_expr))
                next_set = true
            end
        end

        if !next_set
            # Insert named parameters block with chained operation before lambda or other args
            insert!(op.args, 2, Expr(:parameters, Expr(:kw, :next, pipeline_expr)))
        end
        
        pipeline_expr = op
    end

    pipeline_expr
end
