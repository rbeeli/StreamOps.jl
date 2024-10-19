using Dates
import Base.Libc: systemsleep

mutable struct RealtimeTimer{TPeriod,TTime,TAdapterFunc} <: SourceAdapter
    node::StreamNode
    adapter_func::TAdapterFunc
    interval::TPeriod
    start_time::TTime
    task::Union{Task,Nothing}
    stop_flag::Threads.Atomic{Bool}
    stop_check_interval::Dates.Millisecond

    function RealtimeTimer(
        executor,
        node::StreamNode
        ;
        interval::TPeriod,
        start_time::TTime,
        stop_check_interval::Dates.Millisecond=Dates.Millisecond(50)
    ) where {TPeriod,TTime}
        adapter_func = executor.adapter_funcs[node.index]
        stop_flag = Threads.Atomic{Bool}(false)
        new{TPeriod,TTime,typeof(adapter_func)}(
            node, adapter_func, interval, start_time, nothing, stop_flag, stop_check_interval)
    end
end

function worker(timer::RealtimeTimer{TPeriod,TTime}, executor::RealtimeExecutor{TStates,TTime}) where {TPeriod,TStates,TTime}
    time_now = time(executor)
    next_time = _calc_next_time(timer, executor)

    while true
        time_now = time(executor)

        # Check if past end time
        time_now >= end_time(executor) && break

        # Calculate sleep duration
        sleep_us = Dates.Microsecond(min(next_time - time_now, timer.stop_check_interval))

        # Wait until next event (or stop flag check)
        # use Libc.systemsleep(secs) instead of Base.sleep(secs) for more accurate sleep time
        Dates.value(sleep_us) > 0 && systemsleep(Dates.value(sleep_us) / 1_000_000.0)

        # If we've reached or passed next_time, schedule the event and calculate the next time
        if time_now >= next_time
            put!(executor.event_queue, ExecutionEvent(time_now, timer.node.index))
            next_time = _calc_next_time(timer, executor)
        end

        # Check if to stop timer
        timer.stop_flag[] && break
    end

    println("RealtimeTimer: Timer [$(timer.node.label)] thread ended")
end

function _calc_next_time(timer::RealtimeTimer{TPeriod,TTime}, executor::RealtimeExecutor{TStates,TTime}) where {TPeriod,TStates,TTime}
    round_origin(
        time(executor) + timer.interval,
        timer.interval,
        RoundDown,
        origin=timer.start_time)
end

function run!(timer::RealtimeTimer{TPeriod,TTime}, executor::RealtimeExecutor{TStates,TTime}) where {TPeriod,TStates,TTime}
    timer.task = Threads.@spawn worker(timer, executor)
    println("RealtimeTimer: Timer [$(timer.node.label)] thread started")
    nothing
end

function process_event!(
    adapter::RealtimeTimer{TPeriod,TTime},
    executor::RealtimeExecutor{TStates,TTime},
    event::ExecutionEvent{TTime}
) where {TPeriod,TStates,TTime}
    # Execute subgraph based on current value
    adapter.adapter_func(executor, event.timestamp)
    nothing
end

function destroy!(timer::RealtimeTimer{TPeriod,TTime}) where {TPeriod,TTime}
    if !isnothing(timer.task)
        timer.stop_flag[] = true
        wait(timer.task) # will also catch and rethrow any exceptions
        timer.task = nothing
    end
    nothing
end
