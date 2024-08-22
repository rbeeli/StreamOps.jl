mutable struct Buffer{T} <: StreamOperation
    const buffer::Vector{T}
    
    function Buffer{T}() where {T}
        new{T}(T[])
    end

    function Buffer(storage::Vector{T}) where {T}
        new{T}(storage)
    end
end

@inline (op::Buffer)(executor, val) = begin
    push!(op.buffer, val)
    nothing
end

@inline is_valid(op::Buffer) = true

@inline Base.empty!(op::Buffer) = empty!(op.buffer)

@inline get_state(op::Buffer) = op.buffer
