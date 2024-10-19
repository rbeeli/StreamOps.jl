using Dates
import Base.Libc: systemsleep

mutable struct RealtimeIterable{TData,TItem,TAdapterFunc} <: SourceAdapter
    node::StreamNode
    adapter_func::TAdapterFunc
    data::TData
    iterate_state::Union{Nothing,Tuple{TItem,Int}}
    task::Union{Task,Nothing}
    stop_flag::Threads.Atomic{Bool}
    stop_check_interval::Dates.Millisecond
    process_queue::Channel{TItem}

    function RealtimeIterable(
        ::Type{TItem},
        executor::TExecutor,
        node::StreamNode,
        data::TData
        ;
        stop_check_interval::Dates.Millisecond=Dates.Millisecond(50),
        max_queue_size=1024
    ) where {TExecutor<:GraphExecutor,TData,TItem}
        adapter_func = executor.adapter_funcs[node.index]
        stop_flag = Threads.Atomic{Bool}(false)
        new{TData,TItem,typeof(adapter_func)}(
            node,
            adapter_func,
            data,
            nothing, # iterate_state
            nothing, # task
            stop_flag,
            stop_check_interval,
            Channel{TItem}(max_queue_size), # process_queue
        )
    end

    function RealtimeIterable(
        executor::TExecutor,
        node::StreamNode,
        data::TData
        ;
        stop_check_interval::Dates.Millisecond=Dates.Millisecond(50),
        max_queue_size=1024
    ) where {TExecutor<:GraphExecutor,TData}
        eltype(data) != Any || throw(ArgumentError("Element type detected as Any. Use typed HistoricIterable constructor to avoid performance penality of Any."))
        adapter_func = executor.adapter_funcs[node.index]
        stop_flag = Threads.Atomic{Bool}(false)
        new{TData,eltype(data),typeof(adapter_func)}(
            node,
            adapter_func,
            data,
            nothing, # iterate_state
            nothing, # task
            stop_flag,
            stop_check_interval,
            Channel{eltype(data)}(max_queue_size), # process_queue
        )
    end
end

function worker(
    adapter::RealtimeIterable{TData,TItem},
    executor::RealtimeExecutor{TStates,TTime}
) where {TData,TItem,TStates,TTime}
    while !isnothing(adapter.iterate_state)
        next_item = @inbounds adapter.iterate_state[1]
        next_time = @inbounds next_item[1]
        time_now = time(executor)

        # Check if past end time
        time_now >= end_time(executor) && break

        # Calculate sleep duration
        sleep_us = Dates.Microsecond(min(next_time - time_now, adapter.stop_check_interval))

        # Wait until next event (or stop flag check)
        # use Libc.systemsleep(secs) instead of Base.sleep(secs) for more accurate sleep time
        Dates.value(sleep_us) > 0 && systemsleep(Dates.value(sleep_us) / 1_000_000.0)

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

    println("RealtimeIterable: Thread [$(adapter.node.label)] ended")
end

function run!(adapter::RealtimeIterable{TData,TItem}, executor::RealtimeExecutor{TStates,TTime}) where {TData,TItem,TStates,TTime}
    adapter.iterate_state = iterate(adapter.data)

    if !isnothing(adapter.iterate_state)
        adapter.task = Threads.@spawn worker(adapter, executor)
        println("RealtimeIterable: Thread [$(adapter.node.label)] started")
    else
        @warn "RealtimeIterable did not receive any records, doing nothing."
    end

    nothing
end

function process_event!(
    adapter::RealtimeIterable{TData,TItem},
    executor::RealtimeExecutor{TStates,TTime},
    event::ExecutionEvent{TTime}
) where {TData,TItem,TStates,TTime}
    # Execute subgraph based on current value
    if !isready(adapter.process_queue)
        throw(ErrorException("Logic error: process_queue is empty when calling process_event!"))
    end
    time, input_data = take!(adapter.process_queue)
    adapter.adapter_func(executor, input_data)
    nothing
end

function destroy!(adapter::RealtimeIterable{TData,TItem}) where {TData,TItem}
    if !isnothing(adapter.task)
        adapter.stop_flag[] = true
        wait(adapter.task) # will also catch and rethrow any exceptions
        adapter.task = nothing
    end
    nothing
end
