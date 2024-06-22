"""
Calculates fractional change to previous value, also known as percent change.

Formula
=======

`` y = x\\_t / x\\_{t-1} - 1 ``
"""
mutable struct FracChange{In}
    prev_value::In

    FracChange{In}(
        ;
        init_value=one(In)
    ) where {In<:AbstractString} = new{In}(init_value)

    FracChange{In}(
        ;
        init_value=zero(In)
    ) where {In} = new{In}(init_value)
end

# for floating-point numbers
@inline (op::FracChange{In})(value) where {In<:AbstractFloat} = begin
    if op.prev_value == zero(In)
        pct_change = In(NaN) # handle division by zero
    else
        pct_change = value / op.prev_value - one(In)
    end
    op.prev_value = value
    pct_change
end

# for other numeric types, including integers
@inline (op::FracChange{In})(value) where {In} = begin
    if op.prev_value == zero(In)
        pct_change = zero(In) # handle division by zero
    else
        pct_change = (value - op.prev_value) / op.prev_value
    end
    op.prev_value = value
    pct_change
end
