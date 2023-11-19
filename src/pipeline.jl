"""
    @pipeline op1 op2 ...

Constructs a chained operation pipeline, where each operation
is a subtype of `Op`. The operation pipeline is type-stable
due to the chaining of operations at compile-time, i.e.
the last operation is passed to the constructor of the
second last operation, and so on.

Example
=======

    @pipeline OpFunc(x -> abs(x)^2) OpLag{Float64}(1) OpPrint

"""
macro pipeline(ops...)
    # Start with the last operation (which does not take a 'next' argument)
    pipeline_expr = Expr(:call, ops[end])

    # Iterate in reverse order, wrapping each operation around the previous one
    for op in reverse(ops[1:end-1])
        # if expression, add pipeline_expr as last argument
        if op isa Expr && op.head == :call
            push!(op.args, pipeline_expr)
            pipeline_expr = op
        else
            dump(op)
            pipeline_expr = Expr(:call, op, pipeline_expr)
        end
    end

    pipeline_expr
end