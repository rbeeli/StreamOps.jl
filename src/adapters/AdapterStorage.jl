mutable struct AdapterStorage{TData} <: StreamOperation
    data::TData
    
    function AdapterStorage{TData}(data) where {TData}
        new{TData}(data)
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
