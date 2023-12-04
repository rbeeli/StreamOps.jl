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
    const lag::Int64
    index::Int64

    Lag{In}(
        lag::Int64=1
        ;
        init_value::In=zero(In)
    ) where {In} = new{In}(fill(init_value, lag), lag, 1)
end

@inline (state::Lag)(value) = begin
    lagged_value = state.buffer[state.index]
    state.buffer[state.index] = value
    state.index = state.index % state.lag + 1
    lagged_value
end
