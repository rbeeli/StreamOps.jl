using Dates

"""
Encodes timestamps using sine and cosine transformations with a specified time period.
Returns tuple of values in [-1, 1] based on position within the period.

Assumes UNIX epoch start 1970-01-01 as origin.

# Formula
`` y = (sin(2π * mod(t, period) / period), cos(2π * mod(t, period) / period)) ``
"""
mutable struct PeriodicTimeEncoder{T} <: StreamOperation
    const period_nanos::Int64
    current::Tuple{Float64,Float64}
    counter::Int

    function PeriodicTimeEncoder{T}(period::Period) where {T<:Dates.AbstractTime}
        # Convert period to nanoseconds
        nanos = Dates.value(Nanosecond(period))
        new{T}(nanos, (0.0, 0.0), 0)
    end

    function PeriodicTimeEncoder(period::Period)
        PeriodicTimeEncoder{DateTime}(period)
    end
end

@inline function (op::PeriodicTimeEncoder{T})(executor, timestamp::T) where {T<:Dates.AbstractTime}
    # Get position within period in nanoseconds
    position = mod(nanos_since_epoch_zero(timestamp), op.period_nanos)

    # Calculate angle
    angle = 2π * position / op.period_nanos

    # Calculate sine and cosine transformations
    op.current = (sin(angle), cos(angle))
    op.counter += 1

    nothing
end

@inline is_valid(op::PeriodicTimeEncoder) = op.counter > 0

@inline function get_state(op::PeriodicTimeEncoder)::Tuple{Float64,Float64}
    op.current
end
