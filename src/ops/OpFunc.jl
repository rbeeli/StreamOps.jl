"""
Applies arbitrary function.
"""
struct OpFunc{F<:Function,Next<:Op} <: Op
    next::Next
    fn::F

    OpFunc(
        fn::F
        ;
        next::Next=OpNone()
    ) where {F<:Function,Next<:Op} = new{F,Next}(next, fn)
end

@inline (op::OpFunc)(value) = op.next(op.fn(value))
