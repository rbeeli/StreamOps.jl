"""
Applies arbitrary function.
"""
struct OpFunc{F<:Function,Next<:Op} <: Op
    next::Next
    f::F

    OpFunc(func::F, next::Next) where {F<:Function,Next<:Op} =
        new{F,Next}(next, func)
end

@inline (op::OpFunc)(value) = op.next(op.f(value))
