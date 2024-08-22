mutable struct TimerAdapter{TPeriod,TTime,TAdapterFunc}
    node::StreamNode
    adapter_func::TAdapterFunc
    interval::TPeriod
    current_time::TTime
    
    function TimerAdapter{TTime}(executor, node::StreamNode; interval::TPeriod, start_time::TTime) where {TPeriod,TTime}
        adapter_func = executor.adapter_funcs[node.index]
        new{TPeriod,TTime,typeof(adapter_func)}(node, adapter_func, interval, start_time)
    end
end

function setup!(timer::TimerAdapter{TPeriod,TTime}, executor::HistoricExecutor{TStates,TTime}) where {TPeriod,TStates,TTime}
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

function advance!(timer::TimerAdapter{TPeriod,TTime}, executor::HistoricExecutor{TStates,TTime}) where {TPeriod,TStates,TTime}
    # Execute subgraph based on current value
    timer.adapter_func(executor, timer.current_time)

    # Schedule next event
    timer.current_time += timer.interval
    if timer.current_time <= end_time(executor)
        push!(executor.event_queue, ExecutionEvent(timer.current_time, timer.node.index))
    end

    nothing
end
