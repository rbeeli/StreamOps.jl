"""
Maintains a rolling window of values over a time period.
The time period type must be compatible with the `TTime` type used by the executor.

# Type Parameters
- `TTime`: The type used for timestamps (e.g., DateTime, Float64)
- `TValue`: The type of values stored in the buffer
- `copy`: Boolean flag indicating whether to return a copy of the data or a view

# Arguments
- `time_period::Period`: The time period to maintain values for (e.g., Second(30), Minute(5)).
- `interval_mode::Symbol`: Either :open or :closed. Open means the oldest value is excluded, closed means it is included.
- `copy::Bool=false`: If `true`, the result will be a copy of the data,
    otherwise it will be a view into the underlying buffer.

Note that if `copy` is false, the returned view should not be stored for later use,
as it may become invalid when the buffer is modified.
If storage or modification of the values is needed, set `copy` to true or make a copy of the result.
"""
mutable struct TimeWindowBuffer{TTime,TValue,TPeriod,interval_mode,copy} <: StreamOperation
    const time_buffer::Vector{TTime}
    const value_buffer::Vector{TValue}
    const time_period::TPeriod
    const interval_mode::Symbol
    const copy::Bool
    const valid_if_empty::Bool

    function TimeWindowBuffer{TTime,TValue}(
        time_period::TPeriod, interval_mode::Symbol, ; copy::Bool=false, valid_if_empty::Bool=false
    ) where {TTime,TValue,TPeriod}
        new{TTime,TValue,TPeriod,interval_mode,copy}(
            Vector{TTime}(), Vector{TValue}(), time_period, interval_mode, copy, valid_if_empty
        )
    end
end

function reset!(op::TimeWindowBuffer)
    empty!(op.time_buffer)
    empty!(op.value_buffer)
    nothing
end

# tell executor to always sync time with this operation (update_time!)
OperationTimeSync(::TimeWindowBuffer) = true

# Internal function to remove old entries from the buffer,
# where the oldest value right on the cutoff time is excluded.
@inline function update_time!(
    op::TimeWindowBuffer{TTime,TValue,TPeriod,:open}, current_time::TTime
) where {TTime,TValue,TPeriod}
    cutoff_time = current_time - op.time_period
    while !isempty(op.time_buffer) && first(op.time_buffer) <= cutoff_time
        popfirst!(op.time_buffer)
        popfirst!(op.value_buffer)
    end
    nothing
end

# Internal function to remove old entries from the buffer,
# where the oldest value right on the cutoff time is included.
@inline function update_time!(
    op::TimeWindowBuffer{TTime,TValue,TPeriod,:closed}, current_time::TTime
) where {TTime,TValue,TPeriod}
    cutoff_time = current_time - op.time_period
    while !isempty(op.time_buffer) && first(op.time_buffer) < cutoff_time
        popfirst!(op.time_buffer)
        popfirst!(op.value_buffer)
    end
    nothing
end

@inline function (op::TimeWindowBuffer{TTime,TValue,TPeriod,interval_mode})(
    executor, value
) where {TTime,TValue,TPeriod,interval_mode}
    current_time = time(executor)

    # Add new entry
    push!(op.time_buffer, current_time)
    push!(op.value_buffer, value)

    # # Remove old entries outside of time window
    # update_time!(op, current_time)

    nothing
end

@inline function is_valid(op::TimeWindowBuffer{TTime,TValue,TPeriod}) where {TTime,TValue,TPeriod}
    op.valid_if_empty || !isempty(op.value_buffer)
end

@inline function get_state(
    op::TimeWindowBuffer{TTime,TValue,TPeriod,interval_mode,false}
) where {TTime,TValue,TPeriod,interval_mode}
    view(op.value_buffer, :)
end

@inline function get_state(
    op::TimeWindowBuffer{TTime,TValue,TPeriod,interval_mode,true}
) where {TTime,TValue,TPeriod,interval_mode}
    collect(op.value_buffer)
end

export TimeWindowBuffer
