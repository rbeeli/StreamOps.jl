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
    const source_adapters::Vector{SourceAdapter}

    function RealtimeExecutor{TTime}(
        graph::StreamGraph, states::TStates; max_queue_size::Int=typemax(Int)
    ) where {TStates,TTime}
        adapters = Vector{SourceAdapter}(undef, length(graph.source_nodes))
        for (i, ix) in enumerate(graph.source_nodes)
            adapters[i] = getfield(states, graph.nodes[ix].field_name)
        end
        new{TStates,TTime}(
            graph,
            states,
            time_zero(TTime), # start_time
            time_zero(TTime), # end_time
            Channel{ExecutionEvent{TTime}}(max_queue_size), # event_queue
            adapters,
        )
    end
end

# Fake adapter to indicate a wake-up call for executor
struct WakeUpAdapter <: SourceAdapter end
const WAKE_UP_ADAPTER = WakeUpAdapter();

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

function setup!(executor::RealtimeExecutor{TStates,TTime}; debug=false) where {TStates,TTime}
    # Compile source functions
    for (adapter, source_ix) in zip(executor.source_adapters, executor.graph.source_nodes)
        node = executor.graph.nodes[source_ix]
        source_fn = compile_source!(executor, node; debug=debug)
        set_adapter_func!(adapter, source_fn)
    end
end

function run!(
    executor::RealtimeExecutor{TStates,TTime}, start_time::TTime, end_time::TTime
) where {TStates,TTime}
    @assert start_time < end_time "Start time '$start_time' must be before end time '$end_time'"
    @assert !isempty(executor.source_adapters) "No adapters have been defined for RealtimeExecutor"

    # Set executor time bounds
    executor.start_time = start_time
    executor.end_time = end_time

    # need invokelatest because states struct is dynamically compiled,
    # which may live in a newer world age than the caller.
    Base.invokelatest() do
        # Initialize adapters
        adapters = executor.source_adapters
        println("RealtimeExecutor: Setting up adapters...")
        init_secs = @elapsed run!.(adapters, Ref(executor))
        println("RealtimeExecutor: Adapters set up in $(round(sum(init_secs); digits=3))s")
    end

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
                    put!(executor.event_queue, ExecutionEvent(time(executor), WAKE_UP_ADAPTER))
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
        # need invokelatest because states struct is dynamically compiled,
        # which may live in a newer world age than the caller.
        Base.invokelatest() do
            while true
                # wait for next event
                event = take!(executor.event_queue)
                timestamp = event.timestamp
                adapter = event.adapter

                # Check if past end time
                if timestamp > end_time
                    println("RealtimeExecutor: Ended realtime stream at time $(time(executor))")
                    break
                end

                # Events before start_time are NOT filtered currently,
                # useful for initialization purposes.

                # Process event if not wake-up call
                if !isa(adapter, WakeUpAdapter)
                    # # Check if before start time
                    # if timestamp < start_time
                    #     println("RealtimeExecutor: Dropping event from source at time $timestamp before start time $(start_time)")
                    #     continue
                    # end

                    # Execute source function
                    process_event!(adapter, executor, event)
                end
            end
        end
    catch e
        @error "RealtimeExecutor: Unhandled error, aborting: $e"
        rethrow()
    finally
        println("RealtimeExecutor: Destroying adapters...")

        # Stop wake-up thread
        wake_up_stop[] = true
        try
            wait(wake_up_task)
        catch e
            println("RealtimeExecutor: Error stopping wake-up thread: $e")
        end

        destroy!.(executor.source_adapters)
        println("RealtimeExecutor: Adapters destroyed")
    end

    nothing
end

export RealtimeExecutor, start_time, end_time
