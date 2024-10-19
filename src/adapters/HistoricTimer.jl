mutable struct HistoricTimer{TPeriod,TTime,TAdapterFunc} <: SourceAdapter
    node::StreamNode
    adapter_func::TAdapterFunc
    interval::TPeriod
    current_time::TTime
    
    function HistoricTimer{TTime}(executor, node::StreamNode; interval::TPeriod, start_time::TTime) where {TPeriod,TTime}
        adapter_func = executor.adapter_funcs[node.index]
        new{TPeriod,TTime,typeof(adapter_func)}(node, adapter_func, interval, start_time)
    end
end

function setup!(timer::HistoricTimer{TPeriod,TTime}, executor::HistoricExecutor{TStates,TTime}) where {TPeriod,TStates,TTime}
    # Initialize current time of the timer
    if timer.current_time < start_time(executor)
        timer.current_time = start_time(executor)
    end

    if timer.current_time > end_time(executor)
        return
    end

    # Schedule first event
    push!(executor.event_queue, ExecutionEvent(timer.current_time, timer.node.index))

    nothing
end

function process_event!(
    adapter::HistoricTimer{TPeriod,TTime},
    executor::HistoricExecutor{TStates,TTime},
    event::ExecutionEvent{TTime}
) where {TPeriod,TStates,TTime}
    # Execute subgraph based on current value
    adapter.adapter_func(executor, adapter.current_time)
    nothing
end

function advance!(timer::HistoricTimer{TPeriod,TTime}, executor::HistoricExecutor{TStates,TTime}) where {TPeriod,TStates,TTime}
    # Schedule next event
    timer.current_time += timer.interval
    if timer.current_time <= end_time(executor)
        push!(executor.event_queue, ExecutionEvent(timer.current_time, timer.node.index))
    end
    nothing
end
