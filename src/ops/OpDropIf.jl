"""
Drops the passed value if the user-defined function
returns truthy value.
"""
struct OpDropIf{F<:Function,R,Next<:Op} <: Op
    next::Next
    fn::F
    dropped_ret_val::R

    OpDropIf(
        fn::F
        ;
        dropped_ret_val::R=nothing,
        next::Next=OpNone()
    ) where {F<:Function,R,Next<:Op} = new{F,R,Next}(
        next,
        fn,
        dropped_ret_val
    )
end

@inline (op::OpDropIf)(value) = begin
    if op.fn(value)
        return op.dropped_ret_val
    end
    op.next(value)
end
