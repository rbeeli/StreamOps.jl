"""
Lags the passed value by the specified number of steps.
Default lag is 1 (i.e. the previous value).

Formula
=======

    y_t = x_{t-lag}

.
"""
mutable struct OpLag{In,Next<:Op} <: Op
    const next::Next
    const buffer::Vector{In}
    const lag::Int64
    index::Int64

    OpLag{In}(
        lag::Int64=1
        ;
        init_value::In=zero(In),
        next::Next=OpNone()
    ) where {In,Next<:Op} = new{In,Next}(next, fill(init_value, lag), lag, 1)
end

@inline (op::OpLag)(value) = begin
    lagged_value = op.buffer[op.index]
    op.buffer[op.index] = value
    op.index = op.index % op.lag + 1
    op.next(lagged_value)
end
