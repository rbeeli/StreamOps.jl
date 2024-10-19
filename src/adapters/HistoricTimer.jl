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

function setup!(adapter::HistoricTimer{TPeriod,TTime}, executor::HistoricExecutor{TStates,TTime}) where {TPeriod,TStates,TTime}
    # Initialize current time of the timer
    if adapter.current_time < start_time(executor)
        adapter.current_time = start_time(executor)
    end

    if adapter.current_time > end_time(executor)
        return
    end

    # Schedule first event
    push!(executor.event_queue, ExecutionEvent(adapter.current_time, adapter))

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

function advance!(adapter::HistoricTimer{TPeriod,TTime}, executor::HistoricExecutor{TStates,TTime}) where {TPeriod,TStates,TTime}
    # Schedule next event
    adapter.current_time += adapter.interval
    if adapter.current_time <= end_time(executor)
        push!(executor.event_queue, ExecutionEvent(adapter.current_time, adapter))
    end
    nothing
end
