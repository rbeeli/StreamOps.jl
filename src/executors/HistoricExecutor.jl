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
    source_funcs::Vector{Function}
    function HistoricExecutor{TTime}(graph::StreamGraph, states::TStates; start_time::TTime, end_time::TTime) where {TStates,TTime}
        event_queue = BinaryMinHeap{ExecutionEvent{TTime}}()
        source_funcs = Vector{Function}()
        new{TStates,TTime}(graph, states, start_time, end_time, zero(TTime), event_queue, source_funcs)
    end
end

@inline function time(executor::HistoricExecutor{TStates,TTime})::TTime where {TStates,TTime}
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
    executor = HistoricExecutor{TTime}(graph, states; start_time=TTime(zero(TTime)), end_time=TTime(zero(TTime)))

    # Compile source functions
    for source in executor.graph.source_nodes
        source_fn = compile_source!(executor, executor.graph.nodes[source]; debug=debug)
        push!(executor.source_funcs, source_fn)
    end

    executor
end

function run_simulation!(executor::HistoricExecutor{TStates,TTime}, adapters; start_time::TTime, end_time::TTime) where {TStates,TTime}
    @assert start_time < end_time "Start time '$start_time' must be before end time '$end_time'"
    @assert length(adapters) == length(executor.source_funcs) "Number of adapters must match number of source nodes"

    # Set executor time bounds
    executor.start_time = start_time
    executor.end_time = end_time
    executor.current_time = start_time

    # Initialize adapters
    setup!.(adapters, Ref(executor))

    # Process events in chronological order using a priority queue
    while !isempty(executor.event_queue)
        event = pop!(executor.event_queue)
        index = event.source_index
        timestamp = event.timestamp

        # Check if before start time
        if timestamp < start_time
            error("HistoricExecutor: Event from source [$(get_node_label(executor.graph, index))] at time $timestamp is before start time $(start_time)")
        end

        # Check if past end time
        if timestamp > end_time
            break
        end

        # Update the current time of the executor
        executor.current_time = timestamp

        # Execute
        adapter = @inbounds adapters[index]
        advance!(adapter, executor)
    end

    # println("HistoricExecutor: Simulation ended at time $(time(executor))")

    nothing
end