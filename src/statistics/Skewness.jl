using DataStructures

"""
Calculates the moving sample skewness with fixed window size in O(1) time.

# Arguments
- `window_size`: The number of observations to consider in the moving window.

# Notes
- Uses Kahan summation for numerical stability
- Handles edge cases:
  - Returns 0 when n < 3 observations
  - Returns 0 when all values in window are identical
  - Returns 0 when variance is effectively 0 (≤ 1e-14)
- Implements the same method as pandas' rolling skewness calculation

# References
Python pandas implementation of rolling skewness:
* https://pandas.pydata.org/pandas-docs/stable/reference/api/pandas.core.window.rolling.Rolling.skew.html
* https://github.com/pandas-dev/pandas/blob/224c6ff2c3a93779d994fe9a6dcdc2b5a3dc4ad6/pandas/_libs/window/aggregations.pyx#L482
"""
mutable struct Skewness{In<:Number,Out<:Number} <: StreamOperation
    const buffer::CircularBuffer{In}
    const window_size::Int
    x::Out
    xx::Out
    xxx::Out
    compensation_x::Out
    compensation_xx::Out
    compensation_xxx::Out
    num_consecutive_same_value::Int
    prev_value::In

    function Skewness{In,Out}(window_size::Int) where {In<:Number,Out<:Number}
        @assert window_size > 0 "Window size must be greater than 0"
        new{In,Out}(
            CircularBuffer{In}(window_size),
            window_size,
            zero(Out), # x
            zero(Out), # xx
            zero(Out), # xxx
            zero(Out), # compensation_x
            zero(Out), # compensation_xx
            zero(Out), # compensation_xxx
            0, # num_consecutive_same_value
            zero(In), # prev_value
        )
    end
end

function reset!(op::Skewness{In,Out}) where {In,Out}
    empty!(op.buffer)
    op.x = zero(Out)
    op.xx = zero(Out)
    op.xxx = zero(Out)
    op.compensation_x = zero(Out)
    op.compensation_xx = zero(Out)
    op.compensation_xxx = zero(Out)
    op.num_consecutive_same_value = 0
    op.prev_value = zero(In)
    nothing
end

function _add_skew!(op::Skewness{In,Out}, val::In) where {In<:Number,Out<:Number}
    y = val - op.compensation_x
    t = op.x + y
    op.compensation_x = t - op.x - y
    op.x = t

    y = val * val - op.compensation_xx
    t = op.xx + y
    op.compensation_xx = t - op.xx - y
    op.xx = t

    y = val * val * val - op.compensation_xxx
    t = op.xxx + y
    op.compensation_xxx = t - op.xxx - y
    op.xxx = t

    if val == op.prev_value
        op.num_consecutive_same_value += 1
    else
        op.num_consecutive_same_value = 1
    end
    op.prev_value = val
end

function _remove_skew!(op::Skewness{In,Out}, val::In) where {In<:Number,Out<:Number}
    y = -val - op.compensation_x
    t = op.x + y
    op.compensation_x = t - op.x - y
    op.x = t

    y = -(val * val) - op.compensation_xx
    t = op.xx + y
    op.compensation_xx = t - op.xx - y
    op.xx = t

    y = -(val * val * val) - op.compensation_xxx
    t = op.xxx + y
    op.compensation_xxx = t - op.xxx - y
    op.xxx = t
end

function (op::Skewness{In,Out})(executor, value::In) where {In<:Number,Out<:Number}
    if isfull(op.buffer)
        dropped = popfirst!(op.buffer)
        _remove_skew!(op, dropped)
    end

    push!(op.buffer, value)
    _add_skew!(op, value)

    nothing
end

@inline function is_valid(op::Skewness{In,Out}) where {In<:Number,Out<:Number}
    isfull(op.buffer)
end

@inline function get_state(op::Skewness{In,Out})::Out where {In<:Number,Out<:Number}
    minp = 3  # Minimum number of observations for valid skewness
    nobs = length(op.buffer)

    if nobs < minp
        return zero(Out)
    elseif op.num_consecutive_same_value >= nobs
        return zero(Out)
    end

    dnobs = Out(nobs)
    A = op.x / dnobs
    B = op.xx / dnobs - A * A
    C = op.xxx / dnobs - A * A * A - 3 * A * B

    return if B <= 1e-14
        zero(Out)
    else
        R = sqrt(B)
        ((sqrt(dnobs * (dnobs - 1)) * C) / ((dnobs - 2) * R * R * R))
    end
end

export Skewness
