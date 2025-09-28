"""
Encodes weekdays using both sine and cosine transformations.
Returns tuple of values in [-1, 1] based on day of week.
First day of week is configurable (default Monday).

# Formula
`` y = (sin(2π * d / 7), cos(2π * d / 7)) ``
where d is the weekday number (0-6)

# Arguments
- `start_of_week`: Integer representing first day of week (default: Monday)
  Use constants from Dates: Mon=1, Tue=2, ..., Sun=7
"""
mutable struct PeriodicWeekdayEncoder{T} <: StreamOperation
    const start_of_week::Int
    current::Tuple{Float64,Float64}
    counter::Int

    function PeriodicWeekdayEncoder{T}(; start_of_week::Int=Dates.Mon) where {T<:Dates.AbstractTime}
        @assert 1 <= start_of_week <= 7 "start_of_week must be between 1 (Monday) and 7 (Sunday)"
        new{T}(start_of_week, (0.0, 1.0), 0)
    end

    function PeriodicWeekdayEncoder(; start_of_week::Int=Dates.Mon)
        PeriodicWeekdayEncoder{DateTime}(; start_of_week=start_of_week)
    end
end

function reset!(op::PeriodicWeekdayEncoder)
    op.current = (0.0, 1.0)
    op.counter = 0
    nothing
end

@inline function (op::PeriodicWeekdayEncoder{T})(
    executor, timestamp::T
) where {T<:Dates.AbstractTime}
    # Get the day of week (1-7, where 1 is Monday by default)
    weekday = Dates.dayofweek(timestamp)

    # Convert to 0-6 range relative to start_of_week
    day_num = mod(weekday - op.start_of_week, 7)

    # Calculate angle
    angle = 2π * day_num / 7

    # Calculate sine and cosine transformations
    op.current = (sin(angle), cos(angle))
    op.counter += 1
    nothing
end

@inline is_valid(op::PeriodicWeekdayEncoder) = op.counter > 0

@inline function get_state(op::PeriodicWeekdayEncoder)::Tuple{Float64,Float64}
    op.current
end

export PeriodicWeekdayEncoder
