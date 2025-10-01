"""
In-graph storage backing a `source!` node.

`AdapterStorage` keeps the current value emitted by the source alongside the
original value passed during graph compilation so that `reset!` can restore the
source to its initial state when the graph is rewound.
"""
mutable struct AdapterStorage{TData} <: StreamOperation
    data::TData
    initial::TData

    function AdapterStorage{TData}(data) where {TData}
        initial = deepcopy(data)
        new{TData}(deepcopy(data), initial)
    end
end

@inline (storage::AdapterStorage{TData})(executor, data::TData) where {TData} = begin
    storage.data = data
end

@inline function is_valid(storage::AdapterStorage{TData}) where {TData}
    !isnothing(storage.data)
end

@inline function get_state(storage::AdapterStorage{TData}) where {TData}
    storage.data
end

function reset!(storage::AdapterStorage{TData}) where {TData}
    storage.data = deepcopy(storage.initial)
    nothing
end

export AdapterStorage
