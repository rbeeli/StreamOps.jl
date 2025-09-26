using DataStructures

"""
An executor that runs a stream computation graph in historical mode.
Historic means that the executor processes timestamped events that occurred in the past
at full speed, i.e., the current time of the executor is updated to the timestamp of the event.
"""
mutable struct HistoricExecutor{TStates,TTime} <: GraphExecutor
    const graph::StreamGraph
    const states::TStates
    start_time::TTime
    end_time::TTime
    current_time::TTime
    const event_queue::BinaryMinHeap{ExecutionEvent{TTime}}
    const adapters::Vector{SourceAdapter}
    const adapter_funcs::Dict{Int,Function}
    const drop_events_before_start::Bool

    function HistoricExecutor{TTime}(
        graph::StreamGraph, states::TStates; drop_events_before_start::Bool=false
    ) where {TStates,TTime}
        new{TStates,TTime}(
            graph,
            states,
            time_zero(TTime), # start_time
            time_zero(TTime), # end_time
            zero(TTime), # current_time
            BinaryMinHeap{ExecutionEvent{TTime}}(), # event_queue
            Vector{SourceAdapter}(), # adapters
            Dict{Int,Function}(), # adapter_funcs
            drop_events_before_start,
        )
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

function set_adapters!(executor::HistoricExecutor, adapters)
    @assert length(adapters) >= length(executor.adapter_funcs) "Number of executor adapters must be greater than or equal to number of source nodes"
    empty!(executor.adapters)
    append!(executor.adapters, adapters)
end

function setup!(executor::HistoricExecutor{TStates,TTime}; debug=false) where {TStates,TTime}
    # Compile source functions
    for source_ix in executor.graph.source_nodes
        source_fn = compile_source!(executor, executor.graph.nodes[source_ix]; debug=debug)
        executor.adapter_funcs[source_ix] = source_fn
    end
end

function run!(
    executor::HistoricExecutor{TStates,TTime}, start_time::TTime, end_time::TTime
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
            if !executor.drop_events_before_start || timestamp >= start_time
                # Update the current time of the executor
                executor.current_time = timestamp

                # Execute the event
                process_event!(adapter, executor, event)
                # else
                #   println("HistoricExecutor: Event from source [$(get_node_label(executor.graph, index))] at time $timestamp is before start time $start_time")
            end

            # Schedule next event
            advance!(adapter, executor)
        end

        nothing
    end

    # println("HistoricExecutor: Simulation ended at time $(time(executor))")

    nothing
end

export HistoricExecutor, set_adapters!, start_time, end_time
