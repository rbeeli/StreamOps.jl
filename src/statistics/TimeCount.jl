"""
Counts the number of values over a time period.
The time period type must be compatible with the `TTime` type used by the executor.

# Type Parameters
- `TTime`: The type used for timestamps (e.g., DateTime, Float64)

# Arguments
- `time_period::Period`: The time period to maintain the count for (e.g., Second(30), Minute(5)).
- `interval_mode::Symbol`: Either :open or :closed. Open means the oldest value is excluded, closed means it is included.
"""
mutable struct TimeCount{TTime,TPeriod,interval_mode} <: StreamOperation
    const time_buffer::Vector{TTime}
    const time_period::TPeriod
    const interval_mode::Symbol
    current_count::Int

    function TimeCount{TTime}(
        time_period::TPeriod,
        interval_mode::Symbol
    ) where {TTime,TPeriod}
        new{TTime,TPeriod,interval_mode}(
            Vector{TTime}(),
            time_period,
            interval_mode,
            0)
    end
end

# tell executor to always sync time with this operation
StreamOperationTimeSync(::TimeCount) = true

# Internal function to remove old entries from the buffer,
# where the oldest value right on the cutoff time is excluded.
@inline function update_time!(op::TimeCount{TTime,TPeriod,:open}, current_time::TTime) where {TTime,TPeriod}
    cutoff_time = current_time - op.time_period
    removed = 0
    while !isempty(op.time_buffer) && first(op.time_buffer) <= cutoff_time
        popfirst!(op.time_buffer)
        removed += 1
    end
    op.current_count -= removed
    nothing
end

# Internal function to remove old entries from the buffer,
# where the oldest value right on the cutoff time is included.
@inline function update_time!(op::TimeCount{TTime,TPeriod,:closed}, current_time::TTime) where {TTime,TPeriod}
    cutoff_time = current_time - op.time_period
    removed = 0
    while !isempty(op.time_buffer) && first(op.time_buffer) < cutoff_time
        popfirst!(op.time_buffer)
        removed += 1
    end
    op.current_count -= removed
    nothing
end

@inline function (op::TimeCount{TTime,TPeriod,interval_mode})(executor, _) where {TTime,TPeriod,interval_mode}
    current_time = time(executor)

    # Add new entry
    push!(op.time_buffer, current_time)
    op.current_count += 1

    # # Remove old entries outside of time window
    # update_time!(op, current_time)

    nothing
end

@inline function is_valid(op::TimeCount{TTime,TPeriod}) where {TTime,TPeriod}
    !isempty(op.time_buffer)
end

@inline function get_state(op::TimeCount{TTime,TPeriod,interval_mode}) where {TTime,TPeriod,interval_mode}
    op.current_count
end

@inline function Base.empty!(op::TimeCount)
    empty!(op.time_buffer)
    op.current_count = 0
    nothing
end