"""
Lags the passed value by the specified number of steps.
Default lag is 1 (i.e. the previous value).

Formula
=======

    y_t = x_{t-lag}

.
"""
mutable struct Lag{In}
    const buffer::Vector{In}
    const lag::Int
    index::Int

    Lag{In}(
        lag::Int=1
        ;
        init_value::In=zero(In)
    ) where {In} = new{In}(fill(init_value, lag), lag, 1)
end

@inline (op::Lag)(value) = begin
    lagged_value = op.buffer[op.index]
    op.buffer[op.index] = value
    op.index = op.index % op.lag + 1
    lagged_value
end
