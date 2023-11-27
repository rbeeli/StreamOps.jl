"""
Forwards the passed value to multiple operations.
"""
struct OpBroadcast{Next} <: Op
    next::Next

    OpBroadcast(
        ;
        next::Next=[OpNone()]
    ) where {Next} = new{Next}(next)
end

@inline (op::OpBroadcast{Next})(value) where {Next} = begin
    for op in op.next
        op(value)
    end
    nothing
end
