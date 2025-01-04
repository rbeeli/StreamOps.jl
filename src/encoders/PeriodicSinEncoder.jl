using Dates

"""
Encodes timestamps using sine transformation with a specified time period.
Returns values in [-1, 1] based on position within the period.

Assumes UNIX epoch start 1970-01-01 as origin.

# Formula
`` y = sin(2π * mod(t, period) / period) ``
"""
mutable struct PeriodicSinEncoder{T} <: StreamOperation
    const period_nanos::Int64
    current::Float64
    counter::Int

    function PeriodicSinEncoder{T}(period::Period) where {T<:Dates.AbstractTime}
        # Convert period to nanoseconds
        nanos = Dates.value(Nanosecond(period))
        new{T}(nanos, 0.0, 0)
    end

    function PeriodicSinEncoder(period::Period)
        PeriodicSinEncoder{DateTime}(period)
    end
end

@inline function (op::PeriodicSinEncoder{T})(executor, timestamp::T) where {T<:Dates.AbstractTime}
    # Get position within period in nanoseconds
    position = mod(nanos_since_epoch_zero(timestamp), op.period_nanos)

    # Calculate sine transformation
    op.current = sin(2π * position / op.period_nanos)
    op.counter += 1

    nothing
end

@inline is_valid(op::PeriodicSinEncoder) = op.counter > 0

@inline function get_state(op::PeriodicSinEncoder)::Float64
    op.current
end
