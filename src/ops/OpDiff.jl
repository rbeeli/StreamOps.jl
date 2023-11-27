"""
Calculates the difference between the current and lag-number
of steps value in the past.
Default lag is 1 (i.e. the difference to the previous value).

Formula
=======

    y_t = x_t - x_{t-lag}

.
"""
mutable struct OpDiff{In,Next<:Op} <: Op
    const next::Next
    const buffer::Vector{In}
    const lag::Int64
    index::Int64

    OpDiff{In}(
        lag::Int64=1
        ;
        init_value::In=zero(In),
        next::Next=OpNone()
    ) where {In,Next<:Op} = new{In,Next}(next, fill(init_value, lag), lag, 1)
end

@inline (op::OpDiff)(value) = begin
    lagged_value = op.buffer[op.index]
    op.buffer[op.index] = value
    op.index = op.index % op.lag + 1
    op.next(value - lagged_value)
end
