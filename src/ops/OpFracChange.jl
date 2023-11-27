"""
Calculates fractional change to previous value, also known as percent change.

Formula
=======

    y = x_t / x_{t-1} - 1

.
"""
mutable struct OpFracChange{In,Next<:Op} <: Op
    const next::Next
    prev_value::In

    OpFracChange{In}(
        ;
        init_value=one(In),
        next::Next=OpNone()
    ) where {In<:AbstractString,Next<:Op} = new{In,Next}(next, init_value)

    OpFracChange{In}(
        ;
        init_value=zero(In),
        next::Next=OpNone()
    ) where {In,Next<:Op} = new{In,Next}(next, init_value)
end

# for floating-point numbers
@inline (op::OpFracChange{In})(value) where {In<:AbstractFloat} = begin
    if op.prev_value == zero(In)
        pct_change = In(NaN) # handle division by zero
    else
        pct_change = value / op.prev_value - one(In)
    end
    op.prev_value = value
    op.next(pct_change)
end

# for other numeric types, including integers
@inline (op::OpFracChange{In})(value) where {In} = begin
    if op.prev_value == zero(In)
        pct_change = zero(In) # handle division by zero
    else
        pct_change = (value - op.prev_value) / op.prev_value
    end
    op.prev_value = value
    op.next(pct_change)
end
