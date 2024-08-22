mutable struct LiveTimerAdapter{TPeriod,TTime,TSourceFunc}
    node::StreamNode
    source_func::TSourceFunc
    interval::TPeriod
    start_time::TTime
    # timer::Union{Timer,Nothing}
    task::Union{Task,Nothing}
    
    function LiveTimerAdapter{TTime}(executor, node::StreamNode; interval::TPeriod, start_time::TTime) where {TPeriod,TTime}
        source_func = executor.source_funcs[node.index]
        new{TPeriod,TTime,typeof(source_func)}(node, source_func, interval, start_time, nothing)
    end
end

function worker(timer::LiveTimerAdapter{TPeriod,TTime}, executor::RealtimeExecutor{TStates,TTime}) where {TPeriod,TStates,TTime}
    try
        while true
            # Calculate next time to schedule event
            time_now = time(executor)

            # Check if past end time
            if time_now >= end_time(executor)
                break
            end

            # Calculate next time to schedule event
            next_time = round_origin(
                time_now + timer.interval,
                timer.interval,
                mode=RoundDown,
                origin=timer.start_time)

            # Wait until next event
            sleep_duration = next_time - time_now
            sleep(sleep_duration)
        
            # Schedule event for execution
            put!(executor.event_queue, ExecutionEvent(time(executor), timer.node.index))
        end

        println("LiveTimerAdapter: Timer [$(timer.node.label)] task ended")
    catch e
        println("LiveTimerAdapter: Timer [$(timer.node.label)] task ended with error: $e")
    end
end

function run!(timer::LiveTimerAdapter{TPeriod,TTime}, executor::RealtimeExecutor{TStates,TTime}) where {TPeriod,TStates,TTime}
    # i = 0
    # function callback(jl_timer)
    #     (global i += 1; println(i))
    # end
    # timer.timer = Timer(callback, interval=timer.interval)
    # wait(t)
    # sleep(0.5)
    # close(t)

    timer.task = Threads.@spawn worker(timer, executor)

    nothing
end

function process_event!(adapter::LiveTimerAdapter{TPeriod,TTime}, executor::RealtimeExecutor{TStates,TTime}, event::ExecutionEvent{TTime}) where {TPeriod,TStates,TTime}
    # Execute subgraph based on current value
    timestamp = event.timestamp
    adapter.source_func(executor, timestamp)
    nothing
end

function destroy!(timer::LiveTimerAdapter{TPeriod,TTime}) where {TPeriod,TTime}
    # if !isnothing(timer.timer)
    #     close(timer.timer)
    #     timer.timer = nothing
    # end

    if !isnothing(timer.task)
        try
            if istaskstarted(timer.task) && !istaskdone(timer.task)
                Base.throwto(timer.task, InterruptException())
            end
        catch e
            if isa(e, InvalidStateException)
                # already done, ignore
            else
                rethrow() # rethrow unexpected exceptions
            end
        end
        timer.task = nothing
    end

    nothing
end
