mutable struct IterableAdapter{TData,TItem,TAdapterFunc}
    node::StreamNode
    adapter_func::TAdapterFunc
    data::TData
    state::Union{Nothing,Tuple{TItem,Int}}
    
    function IterableAdapter(
        ::Type{TItem},
        executor::TExecutor,
        node::StreamNode, 
        data::TData
    ) where {TExecutor<:GraphExecutor,TItem,TData}
        adapter_func = executor.adapter_funcs[node.index]
        new{TData,TItem,typeof(adapter_func)}(node, adapter_func, data, nothing)
    end

    function IterableAdapter(
        executor::TExecutor,
        node::StreamNode,
        data::TData
    ) where {TExecutor<:GraphExecutor,TData}
        eltype(data) != Any || throw(ArgumentError("Element type detected as Any. Use typed IterableAdapter constructor to avoid performance penality of Any."))
        adapter_func = executor.adapter_funcs[node.index]
        new{TData,eltype(data),typeof(adapter_func)}(node, adapter_func, data, nothing)
    end
end

function setup!(adapter::IterableAdapter{TData}, executor::HistoricExecutor{TStates,TTime}) where {TData,TStates,TTime}
    adapter.state = iterate(adapter.data)

    if !isnothing(adapter.state)
        # Schedule first record
        timestamp, _ = @inbounds adapter.state[1]
        push!(executor.event_queue, ExecutionEvent(timestamp, adapter.node.index))
    end

    nothing
end

function advance!(adapter::IterableAdapter{TData}, executor::HistoricExecutor{TStates,TTime}) where {TData,TStates,TTime}
    # Execute subgraph based on current value
    timestamp, input_data = @inbounds adapter.state[1]
    adapter.adapter_func(executor, input_data)

    # Schedule next record
    adapter.state = iterate(adapter.data, (@inbounds adapter.state[2]))
    if !isnothing(adapter.state)
        timestamp, _ = @inbounds adapter.state[1]
        push!(executor.event_queue, ExecutionEvent(timestamp, adapter.node.index))
    end

    nothing
end


# mutable struct IterableAdapter{TData,TAdapterFunc}
#     node::StreamNode
#     adapter_func::TAdapterFunc
#     data::TData
#     position::Int
    
#     function IterableAdapter(executor, node::StreamNode, data::TData; start_index=1) where {TData}
#         adapter_func = executor.adapter_funcs[node.index]
#         new{TData,typeof(adapter_func)}(node, adapter_func, data, start_index)
#     end
# end

# function setup!(adapter::IterableAdapter{TData}, executor::HistoricExecutor{TStates,TTime}) where {TData,TStates,TTime}
#     if adapter.position > length(adapter.data)
#         return # Empty or no more data available
#     end

#     # Schedule first record
#     timestamp, _ = @inbounds adapter.data[adapter.position]
#     push!(executor.event_queue, ExecutionEvent(timestamp, adapter.node.index))

#     nothing
# end

# function advance!(adapter::IterableAdapter{TData}, executor::HistoricExecutor{TStates,TTime}) where {TData,TStates,TTime}
#     # Execute subgraph based on current value
#     timestamp, input_data = @inbounds adapter.data[adapter.position]
#     adapter.adapter_func(executor, input_data)

#     # Schedule next record
#     if adapter.position < length(adapter.data)
#         adapter.position += 1
#         timestamp, _ = @inbounds adapter.data[adapter.position]
#         push!(executor.event_queue, ExecutionEvent(timestamp, adapter.node.index))
#     end

#     nothing
# end
