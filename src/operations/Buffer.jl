"""
Buffer operation that stores all values in a vector.

A storage vector can be provided to the constructor to
use an existing vector as the underlying storage.

A minimum count can be specified which marks
this operation as valid only when the buffer has at least
`min_count` many values.

# Arguments
- `min_count=0`: The minimum number of values required in the buffer to be considered valid.
- `storage=T[]`: Use provided vector for storage instead of creating a new one.
"""
mutable struct Buffer{T} <: StreamOperation
    const buffer::Vector{T}
    const min_count::Int
    
    function Buffer{T}(; min_count=0) where {T}
        new{T}(T[], min_count)
    end

    function Buffer(storage::Vector{T}; min_count=0) where {T}
        new{T}(storage, min_count)
    end

    function Buffer{T}(storage::Vector{T}; min_count=0) where {T}
        new{T}(storage, min_count)
    end
end

@inline function (op::Buffer)(executor, val)
    push!(op.buffer, val)
    nothing
end

@inline is_valid(op::Buffer) = length(op.buffer) >= op.min_count

@inline get_state(op::Buffer) = op.buffer

@inline Base.empty!(op::Buffer) = empty!(op.buffer)
