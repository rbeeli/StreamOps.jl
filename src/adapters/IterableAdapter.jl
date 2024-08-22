mutable struct IterableAdapter{TData,TSourceFunc}
    node::StreamNode
    source_func::TSourceFunc
    data::TData
    position::Int
    
    function IterableAdapter(executor, node::StreamNode, data::TData; start_index=1) where {TData}
        source_func = executor.source_funcs[node.index]
        new{TData,typeof(source_func)}(node, source_func, data, start_index)
    end
end

function setup!(adapter::IterableAdapter{TData}, executor::HistoricExecutor{TStates,TTime}) where {TData,TStates,TTime}
    if adapter.position > length(adapter.data)
        return # Empty or no more data available
    end

    # Schedule first record
    timestamp, _ = @inbounds adapter.data[adapter.position]
    push!(executor.event_queue, ExecutionEvent(timestamp, adapter.node.index))

    nothing
end

function advance!(adapter::IterableAdapter{TData}, executor::HistoricExecutor{TStates,TTime}) where {TData,TStates,TTime}
    # Execute subgraph based on current value
    timestamp, input_data = @inbounds adapter.data[adapter.position]
    adapter.source_func(executor, input_data)

    # Schedule next record
    if adapter.position < length(adapter.data)
        adapter.position += 1
        timestamp, _ = @inbounds adapter.data[adapter.position]
        push!(executor.event_queue, ExecutionEvent(timestamp, adapter.node.index))
    end

    nothing
end
