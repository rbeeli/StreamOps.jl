using Dates
import Base.Libc: systemsleep

mutable struct RealtimeIterable{TTime,TValue,TData} <: SourceAdapter
    adapter_func::Union{Nothing,Function}
    data::TData
    iterate_state::Union{Nothing,Tuple{Tuple{TTime,TValue},Int}}
    last_value::Base.RefValue{TValue}
    has_value::Bool
    task::Union{Task,Nothing}
    stop_flag::Threads.Atomic{Bool}
    stop_check_interval::Millisecond
    process_queue::Channel{Tuple{TTime,TValue}}
    output_type::Type{TValue}

    function RealtimeIterable(
        ::Type{TValue},
        data::TData;
        stop_check_interval::Millisecond=Millisecond(50),
        max_queue_size=1024,
    ) where {TData,TValue}
        TItem = eltype(data)
        TItem != Any || throw(
            ArgumentError(
                "Element type detected as Any. Use typed RealtimeIterable constructor to avoid performance penalty of Any.",
            ),
        )
        TTime = fieldtype(TItem, 1)
        new{TTime,TValue,TData}(
            nothing,
            data,
            nothing,
            Ref{TValue}(),
            false,
            nothing,
            Threads.Atomic{Bool}(false),
            stop_check_interval,
            Channel{Tuple{TTime,TValue}}(max_queue_size),
            TValue,
        )
    end

    function RealtimeIterable(
        ::Type{TTime},
        ::Type{TValue},
        data::TData;
        stop_check_interval::Millisecond=Millisecond(50),
        max_queue_size=1024,
    ) where {TTime,TValue,TData}
        new{TTime,TValue,TData}(
            nothing,
            data,
            nothing,
            Ref{TValue}(),
            false,
            nothing,
            Threads.Atomic{Bool}(false),
            stop_check_interval,
            Channel{Tuple{TTime,TValue}}(max_queue_size),
            TValue,
        )
    end
end

source_output_type(adapter::RealtimeIterable) = adapter.output_type

function set_adapter_func!(adapter::RealtimeIterable, func::Function)
    adapter.adapter_func = func
    adapter
end

@inline function get_state(
    adapter::RealtimeIterable{TTime,TValue,TData}
) where {TTime,TValue,TData}
    adapter.has_value ? adapter.last_value[] : nothing
end

@inline is_valid(adapter::RealtimeIterable) = adapter.has_value

function worker(
    adapter::RealtimeIterable{TTime,TValue,TData}, executor::RealtimeExecutor{TStates,TTime}
) where {TTime,TValue,TData,TStates}
    while !isnothing(adapter.iterate_state)
        entry, state = adapter.iterate_state
        next_time = @inbounds entry[1]

        # Skip records before the executor's start time
        if next_time < start_time(executor)
            adapter.iterate_state = iterate(adapter.data, state)
            continue
        end

        exec_end = end_time(executor)
        time_now = time(executor)

        # Stop if we have passed the executor window or the record lies beyond it
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
            put!(adapter.process_queue, entry)
            adapter.iterate_state = iterate(adapter.data, state)
        end

        adapter.stop_flag[] && break
    end

    println("RealtimeIterable: Thread ended")
end

function run!(
    adapter::RealtimeIterable{TTime,TValue,TData}, executor::RealtimeExecutor{TStates,TTime}
) where {TTime,TValue,TData,TStates}
    adapter.iterate_state = iterate(adapter.data)

    if !isnothing(adapter.iterate_state)
        adapter.task = Threads.@spawn worker(adapter, executor)
        println("RealtimeIterable: Thread started")
    else
        @warn "RealtimeIterable did not receive any records, doing nothing."
    end

    nothing
end

function process_event!(
    adapter::RealtimeIterable{TTime,TValue,TData},
    executor::RealtimeExecutor{TStates,TTime},
    event::ExecutionEvent{TTime},
) where {TTime,TValue,TData,TStates}
    # Execute subgraph based on current value
    if !isready(adapter.process_queue)
        throw(ErrorException("Logic error: process_queue is empty when calling process_event!"))
    end
    _time, input_data = take!(adapter.process_queue)
    adapter.adapter_func(executor, input_data)
    nothing
end

function destroy!(adapter::RealtimeIterable{TTime,TValue,TData}) where {TTime,TValue,TData}
    if !isnothing(adapter.task)
        adapter.stop_flag[] = true
        wait(adapter.task) # will also catch and rethrow any exceptions
        adapter.task = nothing
    end
    adapter.stop_flag[] = false
    adapter.has_value = false
    while isready(adapter.process_queue)
        take!(adapter.process_queue)
    end
    nothing
end

function reset!(adapter::RealtimeIterable)
    adapter.iterate_state = nothing
    adapter.has_value = false
    adapter.stop_flag[] = false
    while isready(adapter.process_queue)
        take!(adapter.process_queue)
    end
    nothing
end

export RealtimeIterable
