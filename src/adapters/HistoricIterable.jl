mutable struct HistoricIterable{TTime,TValue,TData} <: SourceAdapter
    adapter_func::Union{Nothing,Function}
    data::TData
    iterate_state::Union{Nothing,Tuple{Tuple{TTime,TValue},Int}}
    last_value::Base.RefValue{TValue}
    has_value::Bool
    output_type::Type{TValue}

    function HistoricIterable(::Type{TValue}, data::TData) where {TValue,TData}
        TItem = eltype(data)
        TItem != Any || throw(
            ArgumentError(
                "Element type detected as Any. Use typed HistoricIterable constructor to avoid performance penalty of Any.",
            ),
        )
        TItem <: Tuple || throw(
            ArgumentError(
                "HistoricIterable expects iterable elements that are tuples (timestamp, value); got eltype $(TItem).",
            ),
        )
        TTime = fieldtype(TItem, 1)
        new{TTime,TValue,TData}(nothing, data, nothing, Ref{TValue}(), false, TValue)
    end

    function HistoricIterable(
        ::Type{TTime}, ::Type{TValue}, data::TData
    ) where {TTime,TValue,TData}
        new{TTime,TValue,TData}(nothing, data, nothing, Ref{TValue}(), false, TValue)
    end
end

source_output_type(adapter::HistoricIterable) = adapter.output_type

function set_adapter_func!(adapter::HistoricIterable, func::Function)
    adapter.adapter_func = func
    adapter
end

@inline function get_state(
    adapter::HistoricIterable{TTime,TValue,TData}
) where {TTime,TValue,TData}
    adapter.has_value ? adapter.last_value[] : nothing
end

@inline function is_valid(adapter::HistoricIterable)
    adapter.has_value
end

function setup!(
    adapter::HistoricIterable{TTime,TValue,TData}, executor::HistoricExecutor{TStates,TTime}
) where {TTime,TValue,TData,TStates}
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
    adapter::HistoricIterable{TTime,TValue,TData},
    executor::HistoricExecutor{TStates,TTime},
    event::ExecutionEvent{TTime},
) where {TTime,TValue,TData,TStates}
    # Execute subgraph based on current value
    _, input_data = @inbounds adapter.iterate_state[1]
    adapter.adapter_func(executor, input_data)
    nothing
end

function advance!(
    adapter::HistoricIterable{TTime,TValue,TData},
    executor::HistoricExecutor{TStates,TTime},
) where {TTime,TValue,TData,TStates}
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
