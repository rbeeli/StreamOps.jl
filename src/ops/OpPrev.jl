"""
Returns the previous value of the input, equals a lag 1 operator.
"""
mutable struct OpPrev{In,Next<:Op} <: Op
    const next::Next
    value::In

    OpPrev{In}(
        ;
        init_value=one(In), # zero for default value does not work on strings, use one instead
        next::Next=OpNone()
    ) where {In<:AbstractString,Next<:Op} = new{In,Next}(next, init_value)

    OpPrev{In}(
        ;
        init_value=zero(In),
        next::Next=OpNone()
    ) where {In,Next<:Op} = new{In,Next}(next, init_value)
end

@inline (op::OpPrev)(value) = begin
    tmp = op.value
    op.value = value
    op.next(tmp)
end
