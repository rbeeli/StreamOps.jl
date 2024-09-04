"""
Maintains the sum of values over a time period.
The time period type must be compatible with the `TTime` type used by the executor.

# Type Parameters
- `TTime`: The type used for timestamps (e.g., DateTime, Float64)
- `TValue`: The type of values being summed

# Arguments
- `time_period::Period`: The time period to maintain the sum for (e.g., Second(30), Minute(5)).
- `interval_mode::Symbol`: Either :open or :closed. Open means the oldest value is excluded, closed means it is included.
"""
mutable struct TimeSum{TTime,TValue,TPeriod,interval_mode} <: StreamOperation
    const time_buffer::Vector{TTime}
    const value_buffer::Vector{TValue}
    const time_period::TPeriod
    const interval_mode::Symbol
    current_sum::TValue

    function TimeSum{TTime,TValue}(
        time_period::TPeriod,
        interval_mode::Symbol
    ) where {TTime,TValue,TPeriod}
        new{TTime,TValue,TPeriod,interval_mode}(
            Vector{TTime}(),
            Vector{TValue}(),
            time_period,
            interval_mode,
            zero(TValue))
    end
end

# tell executor to always sync time with this operation
StreamOperationTimeSync(::TimeSum) = true

# Internal function to remove old entries from the buffer,
# where the oldest value right on the cutoff time is excluded.
@inline function update_time!(op::TimeSum{TTime,TValue,TPeriod,:open}, current_time::TTime) where {TTime,TValue,TPeriod}
    cutoff_time = current_time - op.time_period
    while !isempty(op.time_buffer) && first(op.time_buffer) <= cutoff_time
        op.current_sum -= popfirst!(op.value_buffer)
        popfirst!(op.time_buffer)
    end
    nothing
end

# Internal function to remove old entries from the buffer,
# where the oldest value right on the cutoff time is included.
@inline function update_time!(op::TimeSum{TTime,TValue,TPeriod,:closed}, current_time::TTime) where {TTime,TValue,TPeriod}
    cutoff_time = current_time - op.time_period
    while !isempty(op.time_buffer) && first(op.time_buffer) < cutoff_time
        op.current_sum -= popfirst!(op.value_buffer)
        popfirst!(op.time_buffer)
    end
    nothing
end

@inline function (op::TimeSum{TTime,TValue,TPeriod,interval_mode})(executor, value) where {TTime,TValue,TPeriod,interval_mode}
    current_time = time(executor)

    # Add new entry
    push!(op.time_buffer, current_time)
    push!(op.value_buffer, value)
    op.current_sum += value

    # # Remove old entries outside of time window
    # update_time!(op, current_time)

    nothing
end

@inline function is_valid(op::TimeSum{TTime,TValue,TPeriod}) where {TTime,TValue,TPeriod}
    !isempty(op.value_buffer)
end

@inline function get_state(op::TimeSum{TTime,TValue,TPeriod,interval_mode}) where {TTime,TValue,TPeriod,interval_mode}
    op.current_sum
end

@inline function Base.empty!(op::TimeSum)
    empty!(op.time_buffer)
    empty!(op.value_buffer)
    op.current_sum = zero(typeof(op.current_sum))
    nothing
end