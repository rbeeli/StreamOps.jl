mutable struct Buffer{T} <: StreamOperation
    const buffer::Vector{T}
    const min_count::Int
    
    function Buffer{T}(; min_count=0) where {T}
        new{T}(T[], min_count)
    end

    function Buffer(storage::Vector{T}; min_count=0) where {T}
        new{T}(storage, min_count)
    end
end

@inline function (op::Buffer)(executor, val)
    push!(op.buffer, val)
    nothing
end

@inline is_valid(op::Buffer) = length(op.buffer) >= op.min_count

@inline Base.empty!(op::Buffer) = empty!(op.buffer)

@inline get_state(op::Buffer) = op.buffer
