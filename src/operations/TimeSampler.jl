mutable struct TimeSampler{TTime,TValue,TPeriod} <: StreamOperation
    const sample_interval::TPeriod
    const init::TValue
    const origin::TTime
    next_time::TTime
    last_value::TValue
    new_sample::Bool

    function TimeSampler{TTime,TValue}(
        sample_interval::TPeriod; init::TValue=zero(TValue), origin::TTime=time_zero(TTime)
    ) where {TTime,TValue,TPeriod}
        @assert sample_interval > zero(TPeriod) "Sample interval must be positive"
        new{TTime,TValue,TPeriod}(sample_interval, init, origin, origin, init, false)
    end
end

operation_output_type(::TimeSampler{TTime,TValue,TPeriod}) where {TTime,TValue,TPeriod} = TValue

function reset!(op::TimeSampler)
    op.last_value = op.init
    op.next_time = op.origin
    op.new_sample = false
    nothing
end

# tell executor to always sync time with this operation (update_time!)
OperationTimeSync(::TimeSampler) = true

@inline function update_time!(op::TimeSampler{TTime}, current_time::TTime) where {TTime}
    op.new_sample = false
    nothing
end

@inline function (op::TimeSampler{TTime,TValue,TPeriod})(
    executor, value
) where {TTime,TValue,TPeriod}
    current_time = time(executor)

    if current_time >= op.next_time
        op.last_value = value
        op.new_sample = true
        op.next_time = round_origin(current_time, op.sample_interval, RoundUp; origin=op.next_time)
        if op.next_time == current_time
            op.next_time += op.sample_interval
        end
    end

    nothing
end

@inline function is_valid(op::TimeSampler{TTime,TValue,TPeriod}) where {TTime,TValue,TPeriod}
    op.new_sample
end

@inline function get_state(op::TimeSampler{TTime,TValue,TPeriod}) where {TTime,TValue,TPeriod}
    op.last_value
end

export TimeSampler, update_time!
