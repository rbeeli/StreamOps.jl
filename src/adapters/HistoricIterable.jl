mutable struct HistoricIterable{TData,TItem,TOutput} <: SourceAdapter
    adapter_func::Union{Nothing,Function}
    data::TData
    iterate_state::Union{Nothing,Tuple{TItem,Int}}
    last_value::Base.RefValue{TOutput}
    has_value::Bool
    output_type::Type{TOutput}

    function HistoricIterable(::Type{TOutput}, data::TData) where {TOutput,TData}
        eltype(data) != Any || throw(
            ArgumentError(
                "Element type detected as Any. Use typed HistoricIterable constructor to avoid performance penalty of Any.",
            ),
        )
        new{TData,eltype(data),TOutput}(nothing, data, nothing, Ref{TOutput}(), false, TOutput)
    end
end

source_output_type(adapter::HistoricIterable) = adapter.output_type

function set_adapter_func!(adapter::HistoricIterable, func::Function)
    adapter.adapter_func = func
    adapter
end

@inline function get_state(
    adapter::HistoricIterable{TData,TItem,TOutput}
) where {TData,TItem,TOutput}
    adapter.has_value ? adapter.last_value[] : nothing
end

@inline function is_valid(adapter::HistoricIterable)
    adapter.has_value
end

function setup!(
    adapter::HistoricIterable{TData,TItem,TOutput}, executor::HistoricExecutor{TStates,TTime}
) where {TData,TItem,TOutput,TStates,TTime}
    adapter.iterate_state = iterate(adapter.data)
    adapter.has_value = false

    if !isnothing(adapter.iterate_state)
        # Schedule first record
        timestamp, _ = @inbounds adapter.iterate_state[1]
        push!(executor.event_queue, ExecutionEvent(timestamp, adapter))
    end

    nothing
end

function process_event!(
    adapter::HistoricIterable{TData,TItem,TOutput},
    executor::HistoricExecutor{TStates,TTime},
    event::ExecutionEvent{TTime},
) where {TData,TItem,TOutput,TStates,TTime}
    # Execute subgraph based on current value
    _, input_data = @inbounds adapter.iterate_state[1]
    adapter.adapter_func(executor, input_data)
    nothing
end

function advance!(
    adapter::HistoricIterable{TData,TItem,TOutput}, executor::HistoricExecutor{TStates,TTime}
) where {TData,TItem,TOutput,TStates,TTime}
    # Schedule next record
    adapter.iterate_state = iterate(adapter.data, (@inbounds adapter.iterate_state[2]))

    if !isnothing(adapter.iterate_state)
        timestamp, _ = @inbounds adapter.iterate_state[1]
        event = ExecutionEvent(timestamp, adapter)
        push!(executor.event_queue, event)
    end

    nothing
end

function reset!(adapter::HistoricIterable)
    adapter.iterate_state = nothing
    adapter.has_value = false
    nothing
end

export HistoricIterable
