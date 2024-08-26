"""
Prints the value.
The default print function is Julia's `println`.
"""
struct Print{F<:Function} <: StreamOperation
    print_fn::F

    function Print(print_fn::F=println) where {F<:Function}
        new{F}(print_fn)
    end
end

@inline function (op::Print)(executor, value)
    op.print_fn(value)
    nothing
end

@inline is_valid(op::Print) = true

@inline get_state(op::Print) = nothing
