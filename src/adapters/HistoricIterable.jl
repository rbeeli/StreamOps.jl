mutable struct HistoricIterable{TData,TItem,TAdapterFunc} <: SourceAdapter
    node::StreamNode
    adapter_func::TAdapterFunc
    data::TData
    iterate_state::Union{Nothing,Tuple{TItem,Int}}

    function HistoricIterable(
        ::Type{TItem}, executor::TExecutor, node::StreamNode, data::TData
    ) where {TExecutor<:GraphExecutor,TItem,TData}
        adapter_func = executor.adapter_funcs[node.index]
        new{TData,TItem,typeof(adapter_func)}(node, adapter_func, data, nothing)
    end

    function HistoricIterable(
        executor::TExecutor, node::StreamNode, data::TData
    ) where {TExecutor<:GraphExecutor,TData}
        eltype(data) != Any || throw(
            ArgumentError(
                "Element type detected as Any. Use typed HistoricIterable constructor to avoid performance penality of Any.",
            ),
        )
        adapter_func = executor.adapter_funcs[node.index]
        new{TData,eltype(data),typeof(adapter_func)}(node, adapter_func, data, nothing)
    end
end

function setup!(
    adapter::HistoricIterable{TData,TItem,TAdapterFunc}, executor::HistoricExecutor{TStates,TTime}
) where {TData,TItem,TAdapterFunc,TStates,TTime}
    adapter.iterate_state = iterate(adapter.data)

    if !isnothing(adapter.iterate_state)
        # Schedule first record
        timestamp, _ = @inbounds adapter.iterate_state[1]
        push!(executor.event_queue, ExecutionEvent(timestamp, adapter))
    end

    nothing
end

function process_event!(
    adapter::HistoricIterable{TData,TItem,TAdapterFunc},
    executor::HistoricExecutor{TStates,TTime},
    event::ExecutionEvent{TTime},
) where {TData,TItem,TAdapterFunc,TStates,TTime}
    # Execute subgraph based on current value
    _, input_data = @inbounds adapter.iterate_state[1]
    adapter.adapter_func(executor, input_data)
    nothing
end

function advance!(
    adapter::HistoricIterable{TData,TItem,TAdapterFunc}, executor::HistoricExecutor{TStates,TTime}
) where {TData,TItem,TAdapterFunc,TStates,TTime}
    # Schedule next record
    adapter.iterate_state = iterate(adapter.data, (@inbounds adapter.iterate_state[2]))

    if !isnothing(adapter.iterate_state)
        timestamp, _ = @inbounds adapter.iterate_state[1]
        event = ExecutionEvent(timestamp, adapter)
        push!(executor.event_queue, event)
    end

    nothing
end

export HistoricIterable
