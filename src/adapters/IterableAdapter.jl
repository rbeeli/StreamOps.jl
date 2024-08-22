mutable struct IterableAdapter{TData,TAdapterFunc}
    node::StreamNode
    adapter_func::TAdapterFunc
    data::TData
    position::Int
    
    function IterableAdapter(executor, node::StreamNode, data::TData; start_index=1) where {TData}
        adapter_func = executor.adapter_funcs[node.index]
        new{TData,typeof(adapter_func)}(node, adapter_func, data, start_index)
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
    adapter.adapter_func(executor, input_data)

    # Schedule next record
    if adapter.position < length(adapter.data)
        adapter.position += 1
        timestamp, _ = @inbounds adapter.data[adapter.position]
        push!(executor.event_queue, ExecutionEvent(timestamp, adapter.node.index))
    end

    nothing
end
