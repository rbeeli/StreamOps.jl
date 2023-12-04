"""
Calculates the difference between the current and lag-number
of steps value in the past.
Default lag is 1 (i.e. the difference to the previous value).

Formula
=======

    y_t = x_t - x_{t-lag}

.
"""
mutable struct Diff{In}
    const buffer::Vector{In}
    const lag::Int64
    index::Int64

    Diff{In}(
        lag::Int64=1
        ;
        init_value::In=zero(In)
    ) where {In} = new{In}(fill(init_value, lag), lag, 1)
end

@inline function (state::Diff{In})(value::In)::In where {In}
    lagged_value = @inbounds state.buffer[state.index]
    @inbounds state.buffer[state.index] = value
    state.index = state.index % state.lag + 1
    value - lagged_value
end
