using Dates

"""
An executor that runs a stream computation graph in realtime mode.
Time is always reported as the current system time, i.e. "now".
The realtime mode is usually used for live data processing in productive environments
where data flows in as time passes by.
"""
mutable struct RealtimeExecutor{TStates,TTime} <: GraphExecutor
    graph::StreamGraph
    states::TStates
    start_time::TTime
    end_time::TTime
    event_queue::Channel{ExecutionEvent{TTime}}
    adapter_funcs::Vector{Function}
    function RealtimeExecutor{TTime}(
        graph::StreamGraph,
        states::TStates
        ;
        start_time::TTime,
        end_time::TTime
    ) where {TStates,TTime}
        event_queue = Channel{ExecutionEvent{TTime}}(128)
        adapter_funcs = Vector{Function}()
        new{TStates,TTime}(graph, states, start_time, end_time, event_queue, adapter_funcs)
    end
end

"""
Returns the current system time in UTC, i.e. real (wall-clock) time.
"""
@inline function Base.time(executor::RealtimeExecutor{TStates,TTime})::TTime where {TStates,TTime}
    time_now(TTime)
end

@inline function start_time(executor::RealtimeExecutor{TStates,TTime})::TTime where {TStates,TTime}
    executor.start_time
end

@inline function end_time(executor::RealtimeExecutor{TStates,TTime})::TTime where {TStates,TTime}
    executor.end_time
end

function compile_realtime_executor(::Type{TTime}, graph::StreamGraph; debug=false) where {TTime}
    states = compile_graph!(TTime, graph; debug=debug)
    executor = RealtimeExecutor{TTime}(
        graph,
        states,
        start_time=time_zero(TTime),
        end_time=time_zero(TTime)
    )

    # Compile source functions
    for source in executor.graph.source_nodes
        source_fn = compile_source!(executor, executor.graph.nodes[source]; debug=debug)
        push!(executor.adapter_funcs, source_fn)
    end

    executor
end

function run_realtime!(executor::RealtimeExecutor{TStates,TTime}, adapters; start_time::TTime, end_time::TTime) where {TStates,TTime}
    @assert start_time < end_time "Start time '$start_time' must be before end time '$end_time'"
    @assert length(adapters) == length(executor.adapter_funcs) "Number of adapters must match number of source nodes"

    # Set executor time bounds
    executor.start_time = start_time
    executor.end_time = end_time

    # Initialize adapters
    println("RealtimeExecutor: Setting up adapters...")
    init_secs = @elapsed run!.(adapters, Ref(executor))
    println("RealtimeExecutor: Adapters set up in $(round(sum(init_secs); digits=3))s")

    # Start periodic wake-up thread so that
    # the condition to end if current time is past end time
    # is checked even if no events are in the queue.
    wake_up_stop = Threads.Atomic{Bool}(false)
    wake_up_task = Threads.@spawn begin
        try
            while !wake_up_stop[]
                sleep(0.1)

                # Wake-up call if no events in queue
                if !isready(executor.event_queue)
                    put!(executor.event_queue, ExecutionEvent(time(executor), -1))
                end
            end
        catch e
            @error "RealtimeExecutor: Wake-up thread error: $e"
            if !isa(e, InterruptException)
                rethrow(e)
            end
        end
    end

    # Process events using Channel (synchronized FIFO queue)
    try
        while true
            # wait for next event
            event = take!(executor.event_queue)
            index = event.source_index
            timestamp = event.timestamp

            # Check if past end time
            if timestamp > end_time
                println("RealtimeExecutor: Ended realtime stream at time $(time(executor))")
                break
            end

            # Process event if not wake-up call
            if index != -1
                # Check if before start time
                if timestamp < start_time
                    println("RealtimeExecutor: Dropping event from source [$(get_node_label(executor.graph, index))] at time $timestamp before start time $(start_time)")
                    continue
                end

                # Execute source function
                adapter = @inbounds adapters[index]
                process_event!(adapter, executor, event)
            end
        end
    catch e
        @error "RealtimeExecutor: Unhandled error, aborting: $e"
        rethrow()
    finally
        # Stop wake-up thread
        wake_up_stop[] = true
        try
            wait(wake_up_task)
        catch e
            println("RealtimeExecutor: Error stopping wake-up thread: $e")
        end

        # Destroy adapters
        println("RealtimeExecutor: Destroying adapters...")
        destroy!.(adapters)
        println("RealtimeExecutor: Adapters destroyed")
    end

    nothing
end