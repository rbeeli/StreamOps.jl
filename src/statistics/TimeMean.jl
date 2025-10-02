"""
Maintains the mean of values over a time period.
The time period type must be compatible with the `TTime` type used by the executor.

# Type Parameters
- `TTime`: The type used for timestamps (e.g., DateTime, Float64)
- `TIn`: The type of values being averages
- `TOut`: The type of the mean value

# Arguments
- `time_period::Period`: The time period to maintain the average for (e.g., Second(30), Minute(5)).
- `interval_mode::Symbol`: Either :open or :closed. Open means the oldest value is excluded, closed means it is included.
"""
mutable struct TimeMean{TTime,TIn,TOut,TPeriod,interval_mode} <: StreamOperation
    const time_buffer::Vector{TTime}
    const value_buffer::Vector{TIn}
    const time_period::TPeriod
    const interval_mode::Symbol
    const empty_valid::Bool
    const empty_value::TOut
    current_sum::TIn

    function TimeMean{TTime,TIn,TOut}(
        time_period::TPeriod,
        interval_mode::Symbol;
        empty_valid::Bool=false,
        empty_value::TOut=TOut(NaN),
    ) where {TTime,TIn,TOut,TPeriod}
        new{TTime,TIn,TOut,TPeriod,interval_mode}(
            Vector{TTime}(),
            Vector{TIn}(),
            time_period,
            interval_mode,
            empty_valid,
            empty_value,
            zero(TIn),
        )
    end
end

function reset!(
    op::TimeMean{TTime,TIn,TOut,TPeriod,interval_mode}
) where {TTime,TIn,TOut,TPeriod,interval_mode}
    empty!(op.time_buffer)
    empty!(op.value_buffer)
    op.current_sum = zero(TIn)
    nothing
end

# tell executor to always sync time with this operation (update_time!)
OperationTimeSync(::TimeMean) = true

# Internal function to remove old entries from the buffer,
# where the oldest value right on the cutoff time is excluded.
@inline function update_time!(
    op::TimeMean{TTime,TIn,TOut,TPeriod,:open}, current_time::TTime
) where {TTime,TIn,TOut,TPeriod}
    cutoff_time = current_time - op.time_period
    while !isempty(op.time_buffer) && first(op.time_buffer) <= cutoff_time
        op.current_sum -= popfirst!(op.value_buffer)
        popfirst!(op.time_buffer)
    end
    nothing
end

# Internal function to remove old entries from the buffer,
# where the oldest value right on the cutoff time is included.
@inline function update_time!(
    op::TimeMean{TTime,TIn,TOut,TPeriod,:closed}, current_time::TTime
) where {TTime,TIn,TOut,TPeriod}
    cutoff_time = current_time - op.time_period
    while !isempty(op.time_buffer) && first(op.time_buffer) < cutoff_time
        op.current_sum -= popfirst!(op.value_buffer)
        popfirst!(op.time_buffer)
    end
    nothing
end

@inline function (op::TimeMean{TTime,TIn,TOut,TPeriod,interval_mode})(
    executor, value
) where {TTime,TIn,TOut,TPeriod,interval_mode}
    current_time = time(executor)

    # Add new entry
    push!(op.time_buffer, current_time)
    push!(op.value_buffer, value)
    op.current_sum += value

    # # Remove old entries outside of time window
    # update_time!(op, current_time)

    nothing
end

@inline function is_valid(op::TimeMean{TTime,TIn,TOut,TPeriod}) where {TTime,TIn,TOut,TPeriod}
    op.empty_valid || !isempty(op.value_buffer)
end

@inline function get_state(
    op::TimeMean{TTime,TIn,TOut,TPeriod,interval_mode}
)::TOut where {TTime,TIn,TOut,TPeriod,interval_mode}
    n = length(op.value_buffer)
    n == 0 ? op.empty_value : op.current_sum / n
end

operation_output_type(::TimeMean{TTime,TIn,TOut,TPeriod,interval_mode}) where {TTime,TIn,TOut,TPeriod,interval_mode} =
    TOut

export TimeMean, update_time!
