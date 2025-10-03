using Dates
import Base.Libc: systemsleep

mutable struct RealtimeTimer{TPeriod,TTime} <: SourceAdapter
    adapter_func::Union{Nothing,Function}
    interval::TPeriod
    start_time::TTime
    last_value::Base.RefValue{TTime}
    has_value::Bool
    task::Union{Task,Nothing}
    stop_flag::Threads.Atomic{Bool}
    stop_check_interval::Millisecond

    function RealtimeTimer{TTime}(;
        interval::TPeriod, start_time::TTime, stop_check_interval::Millisecond=Millisecond(50)
    ) where {TPeriod,TTime}
        new{TPeriod,TTime}(
            nothing,
            interval,
            start_time,
            Ref{TTime}(start_time),
            true,
            nothing,
            Threads.Atomic{Bool}(false),
            stop_check_interval,
        )
    end
end

function RealtimeTimer(;
    interval::TPeriod, start_time::TTime, stop_check_interval::Millisecond=Millisecond(50)
) where {TPeriod,TTime}
    RealtimeTimer{TTime}(;
        interval=interval, start_time=start_time, stop_check_interval=stop_check_interval
    )
end

source_output_type(::RealtimeTimer{TPeriod,TTime}) where {TPeriod,TTime} = TTime

function set_adapter_func!(adapter::RealtimeTimer, func::Function)
    adapter.adapter_func = func
    adapter
end

@inline get_state(adapter::RealtimeTimer{TPeriod,TTime}) where {TPeriod,TTime} =
    adapter.last_value[]

@inline is_valid(adapter::RealtimeTimer) = adapter.has_value

function worker(
    adapter::RealtimeTimer{TPeriod,TTime}, executor::RealtimeExecutor{TStates,TTime}
) where {TPeriod,TStates,TTime}
    exec_start = start_time(executor)
    exec_end = end_time(executor)
    next_time = max(_calc_next_time(adapter, executor), exec_start)

    while true
        time_now = time(executor)

        # Stop if outside executor window or our next trigger lies beyond it
        (time_now >= exec_end || next_time > exec_end) && break

        sleep_delta = next_time - time_now
        sleep_delta = max(sleep_delta, zero(sleep_delta))
        sleep_delta = min(sleep_delta, adapter.stop_check_interval)
        sleep_ns = Nanosecond(sleep_delta)

        Dates.value(sleep_ns) > 0 && systemsleep(Dates.value(sleep_ns) / 1e9)

        time_now = time(executor)
        time_now >= exec_end && break

        if time_now >= next_time
            put!(executor.event_queue, ExecutionEvent(next_time, adapter))
            next_time = _calc_next_time(adapter, executor)
        end

        adapter.stop_flag[] && break
    end

    println("RealtimeTimer: Timer thread ended")
end

function _calc_next_time(
    adapter::RealtimeTimer{TPeriod,TTime}, executor::RealtimeExecutor{TStates,TTime}
) where {TPeriod,TStates,TTime}
    round_origin(
        time(executor) + adapter.interval, adapter.interval, RoundDown; origin=adapter.start_time
    )
end

function run!(
    adapter::RealtimeTimer{TPeriod,TTime}, executor::RealtimeExecutor{TStates,TTime}
) where {TPeriod,TStates,TTime}
    adapter.task = Threads.@spawn worker(adapter, executor)
    println("RealtimeTimer: Timer thread started")
    nothing
end

function process_event!(
    adapter::RealtimeTimer{TPeriod,TTime},
    executor::RealtimeExecutor{TStates,TTime},
    event::ExecutionEvent{TTime},
) where {TPeriod,TStates,TTime}
    # Execute subgraph based on current value
    adapter.adapter_func(executor, event.timestamp)
    nothing
end

function destroy!(adapter::RealtimeTimer{TPeriod,TTime}) where {TPeriod,TTime}
    if !isnothing(adapter.task)
        adapter.stop_flag[] = true
        wait(adapter.task) # will also catch and rethrow any exceptions
        adapter.task = nothing
    end
    adapter.stop_flag[] = false
    adapter.last_value[] = adapter.start_time
    adapter.has_value = true
    nothing
end

function reset!(adapter::RealtimeTimer)
    adapter.last_value[] = adapter.start_time
    adapter.has_value = true
    adapter.stop_flag[] = false
    nothing
end

export RealtimeTimer
