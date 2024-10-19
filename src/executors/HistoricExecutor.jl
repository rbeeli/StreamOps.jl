using DataStructures

"""
An executor that runs a stream computation graph in historic mode.
Historic means that the executor processes timestamped events that occurred in the past
at full speed, i.e., the current time of the executor is updated to the timestamp of the event.
"""
mutable struct HistoricExecutor{TStates,TTime} <: GraphExecutor
    graph::StreamGraph
    states::TStates
    start_time::TTime
    end_time::TTime
    current_time::TTime
    event_queue::BinaryMinHeap{ExecutionEvent{TTime}}
    adapters::Vector{SourceAdapter}
    adapter_funcs::Vector{Function}
    function HistoricExecutor{TTime}(graph::StreamGraph, states::TStates, start_time::TTime, end_time::TTime) where {TStates,TTime}
        event_queue = BinaryMinHeap{ExecutionEvent{TTime}}()
        adapter_funcs = Vector{Function}()
        new{TStates,TTime}(
            graph,
            states,
            start_time,
            end_time,
            zero(TTime),
            event_queue,
            Vector{SourceAdapter}(),
            adapter_funcs)
    end
end

@inline function Base.time(executor::HistoricExecutor{TStates,TTime})::TTime where {TStates,TTime}
    executor.current_time
end

@inline function start_time(executor::HistoricExecutor{TStates,TTime})::TTime where {TStates,TTime}
    executor.start_time
end

@inline function end_time(executor::HistoricExecutor{TStates,TTime})::TTime where {TStates,TTime}
    executor.end_time
end

function compile_historic_executor(::Type{TTime}, graph::StreamGraph; debug=false) where {TTime}
    states = compile_graph!(TTime, graph; debug=debug)
    executor = HistoricExecutor{TTime}(graph, states, time_zero(TTime), time_zero(TTime))

    # Compile source functions
    for source in executor.graph.source_nodes
        source_fn = compile_source!(executor, executor.graph.nodes[source]; debug=debug)
        push!(executor.adapter_funcs, source_fn)
    end

    executor
end

function set_adapters!(executor::HistoricExecutor, adapters)
    @assert length(adapters) == length(executor.adapter_funcs) "Number of adapters must match number of source nodes"
    executor.adapters = collect(adapters)
end

function run!(
    executor::HistoricExecutor{TStates,TTime},
    start_time::TTime,
    end_time::TTime
) where {TStates,TTime}
    @assert start_time <= end_time "Start time cannot be after end time"
    @assert !isempty(executor.adapters) "No adapters have been defined for HistoricExecutor"
    
    # Set executor time bounds
    executor.start_time = start_time
    executor.end_time = end_time
    executor.current_time = start_time
    
    # need invokelatest because states struct is dynamically compiled,
    # which may live in a newer world age than the caller.
    Base.invokelatest() do
        adapters = executor.adapters
        event_queue = executor.event_queue

        # Initialize adapters
        setup!.(adapters, Ref(executor))

        # Process events in chronological order using a priority queue
        while !isempty(event_queue)
            event = pop!(event_queue)
            timestamp = event.timestamp
            adapter = event.adapter

            # Stop loop if reached end time
            if timestamp > end_time
                break
            end

            # Ignore records before start time
            if timestamp >= start_time
                # Update the current time of the executor
                executor.current_time = timestamp

                # Execute the event
                process_event!(adapter, executor, event)
            # else
                # println("HistoricExecutor: Event from source [$(get_node_label(executor.graph, index))] at time $timestamp is before start time $start_time")
            end

            # Schedule next event
            advance!(adapter, executor)
        end

        nothing
    end

    # println("HistoricExecutor: Simulation ended at time $(time(executor))")

    nothing
end
