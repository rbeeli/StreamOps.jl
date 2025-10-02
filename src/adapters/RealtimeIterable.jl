using Dates
import Base.Libc: systemsleep

mutable struct RealtimeIterable{TData,TItem,TOutput} <: SourceAdapter
    adapter_func::Union{Nothing,Function}
    data::TData
    iterate_state::Union{Nothing,Tuple{TItem,Int}}
    last_value::Base.RefValue{TOutput}
    has_value::Bool
    task::Union{Task,Nothing}
    stop_flag::Threads.Atomic{Bool}
    stop_check_interval::Millisecond
    process_queue::Channel{TItem}
    output_type::Type{TOutput}

    function RealtimeIterable(
        ::Type{TOutput},
        data::TData;
        stop_check_interval::Millisecond=Millisecond(50),
        max_queue_size=1024,
    ) where {TData,TOutput}
        TItem = eltype(data)
        TItem != Any || throw(
            ArgumentError(
                "Element type detected as Any. Use typed RealtimeIterable constructor to avoid performance penalty of Any.",
            ),
        )
        new{TData,TItem,TOutput}(
            nothing,
            data,
            nothing,
            Ref{TOutput}(),
            false,
            nothing,
            Threads.Atomic{Bool}(false),
            stop_check_interval,
            Channel{TItem}(max_queue_size),
            TOutput,
        )
    end
end

source_output_type(adapter::RealtimeIterable) = adapter.output_type

function set_adapter_func!(adapter::RealtimeIterable, func::Function)
    adapter.adapter_func = func
    adapter
end

@inline function get_state(
    adapter::RealtimeIterable{TData,TItem,TOutput}
) where {TData,TItem,TOutput}
    adapter.has_value ? adapter.last_value[] : nothing
end

@inline is_valid(adapter::RealtimeIterable) = adapter.has_value

function worker(
    adapter::RealtimeIterable{TData,TItem,TOutput}, executor::RealtimeExecutor{TStates,TTime}
) where {TData,TItem,TOutput,TStates,TTime}
    while !isnothing(adapter.iterate_state)
        next_item = @inbounds adapter.iterate_state[1]
        next_time = @inbounds next_item[1]
        time_now = time(executor)

        # Check if past end time
        time_now >= end_time(executor) && break

        # Calculate sleep duration
        sleep_ns = Nanosecond(min(next_time - time_now, adapter.stop_check_interval))

        # Wait until next event (or stop flag check)
        # use Libc.systemsleep(secs) instead of Base.sleep(secs) for more accurate sleep time
        Dates.value(sleep_ns) > 0 && systemsleep(Dates.value(sleep_ns) / 1e9)

        # If we've reached or passed next_time, schedule the event and calculate the next time
        if time_now >= next_time
            put!(executor.event_queue, ExecutionEvent(time_now, adapter))
            put!(adapter.process_queue, next_item)
            # next item in iterable
            adapter.iterate_state = iterate(adapter.data, (@inbounds adapter.iterate_state[2]))
        end

        # Check if to stop
        adapter.stop_flag[] && break
    end

    println("RealtimeIterable: Thread ended")
end

function run!(
    adapter::RealtimeIterable{TData,TItem,TOutput}, executor::RealtimeExecutor{TStates,TTime}
) where {TData,TItem,TOutput,TStates,TTime}
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
    adapter::RealtimeIterable{TData,TItem,TOutput},
    executor::RealtimeExecutor{TStates,TTime},
    event::ExecutionEvent{TTime},
) where {TData,TItem,TOutput,TStates,TTime}
    # Execute subgraph based on current value
    if !isready(adapter.process_queue)
        throw(ErrorException("Logic error: process_queue is empty when calling process_event!"))
    end
    _time, input_data = take!(adapter.process_queue)
    adapter.adapter_func(executor, input_data)
    nothing
end

function destroy!(adapter::RealtimeIterable{TData,TItem,TOutput}) where {TData,TItem,TOutput}
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
