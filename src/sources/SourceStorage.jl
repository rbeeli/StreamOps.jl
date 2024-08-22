mutable struct SourceStorage{TData} <: StreamOperation
    data::TData
    
    function SourceStorage{TData}(data) where {TData}
        new{TData}(data)
    end
end

@inline (storage::SourceStorage{TData})(executor, data::TData) where {TData} = begin
    storage.data = data
end

@inline is_valid(storage::SourceStorage{TData}) where {TData} = !isnothing(storage.data)

@inline get_state(storage::SourceStorage{TData}) where {TData} = storage.data
