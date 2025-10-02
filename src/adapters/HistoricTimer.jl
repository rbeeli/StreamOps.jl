mutable struct HistoricTimer{TPeriod,TTime} <: SourceAdapter
    adapter_func::Union{Nothing,Function}
    interval::TPeriod
    start_time::TTime
    current_time::TTime
    last_value::Base.RefValue{TTime}
    has_value::Bool

    function HistoricTimer{TTime}(; interval::TPeriod, start_time::TTime) where {TPeriod,TTime}
        new{TPeriod,TTime}(nothing, interval, start_time, start_time, Ref{TTime}(start_time), true)
    end
end

function HistoricTimer(; interval::TPeriod, start_time::TTime) where {TPeriod,TTime}
    HistoricTimer{TTime}(; interval=interval, start_time=start_time)
end

source_output_type(::HistoricTimer{TPeriod,TTime}) where {TPeriod,TTime} = TTime

function set_adapter_func!(adapter::HistoricTimer, func::Function)
    adapter.adapter_func = func
    adapter
end

@inline get_state(adapter::HistoricTimer{TPeriod,TTime}) where {TPeriod,TTime} =
    adapter.last_value[]

@inline is_valid(adapter::HistoricTimer) = adapter.has_value

function reset!(adapter::HistoricTimer)
    adapter.current_time = adapter.start_time
    adapter.last_value[] = adapter.start_time
    adapter.has_value = true
    nothing
end

function setup!(
    adapter::HistoricTimer{TPeriod,TTime}, executor::HistoricExecutor{TStates,TTime}
) where {TPeriod,TStates,TTime}
    # Initialize current time of the timer
    adapter.current_time = max(adapter.start_time, start_time(executor))
    adapter.last_value[] = adapter.current_time
    adapter.has_value = true

    if adapter.current_time > end_time(executor)
        return nothing
    end

    # Schedule first event
    push!(executor.event_queue, ExecutionEvent(adapter.current_time, adapter))

    nothing
end

function process_event!(
    adapter::HistoricTimer{TPeriod,TTime},
    executor::HistoricExecutor{TStates,TTime},
    event::ExecutionEvent{TTime},
) where {TPeriod,TStates,TTime}
    # Execute subgraph based on current value
    adapter.adapter_func(executor, adapter.current_time)
    nothing
end

function advance!(
    adapter::HistoricTimer{TPeriod,TTime}, executor::HistoricExecutor{TStates,TTime}
) where {TPeriod,TStates,TTime}
    # Schedule next event
    adapter.current_time += adapter.interval
    if adapter.current_time <= end_time(executor)
        event = ExecutionEvent(adapter.current_time, adapter)
        push!(executor.event_queue, event)
    end
    nothing
end

export HistoricTimer
