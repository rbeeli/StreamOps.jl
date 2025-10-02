"""
Prints the value.
The default print function is Julia's `println`.
"""
struct Print{F<:Function} <: StreamOperation
    print_fn::F

    function Print(print_fn::F=(exe, x) -> println(x)) where {F<:Function}
        new{F}(print_fn)
    end
end

operation_output_type(::Print) = Nothing

function reset!(op::Print)
    nothing
end

@inline function (op::Print)(executor, value)
    op.print_fn(executor, value)
    nothing
end

@inline is_valid(op::Print) = true

@inline get_state(op::Print) = nothing

export Print
