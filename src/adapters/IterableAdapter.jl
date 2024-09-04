mutable struct IterableAdapter{TData,TItem,TAdapterFunc}
    node::StreamNode
    adapter_func::TAdapterFunc
    data::TData
    iterate_state::Union{Nothing,Tuple{TItem,Int}}
    
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
    adapter.iterate_state = iterate(adapter.data)

    if !isnothing(adapter.iterate_state)
        # Schedule first record
        timestamp, _ = @inbounds adapter.iterate_state[1]
        push!(executor.event_queue, ExecutionEvent(timestamp, adapter.node.index))
    end

    nothing
end

function process_event!(
    adapter::IterableAdapter{TData},
    executor::HistoricExecutor{TStates,TTime},
    event::ExecutionEvent{TTime}
) where {TData,TStates,TTime}
    # Execute subgraph based on current value
    _, input_data = @inbounds adapter.iterate_state[1]
    adapter.adapter_func(executor, input_data)
    nothing
end

function advance!(adapter::IterableAdapter{TData}, executor::HistoricExecutor{TStates,TTime}) where {TData,TStates,TTime}
    # Schedule next record
    adapter.iterate_state = iterate(adapter.data, (@inbounds adapter.iterate_state[2]))
    if !isnothing(adapter.iterate_state)
        timestamp, _ = @inbounds adapter.iterate_state[1]
        push!(executor.event_queue, ExecutionEvent(timestamp, adapter.node.index))
    end
    nothing
end
