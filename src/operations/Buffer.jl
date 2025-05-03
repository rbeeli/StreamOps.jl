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
- `auto_cast=false`: Enable auto-casting to target type of any input type.
"""
mutable struct Buffer{T,auto_cast} <: StreamOperation
    const buffer::Vector{T}
    const min_count::Int
    const auto_cast::Bool

    function Buffer{T}(; min_count=0, auto_cast::Bool=false) where {T}
        new{T,auto_cast}(T[], min_count, auto_cast)
    end

    function Buffer(storage::Vector{T}; min_count=0, auto_cast::Bool=false) where {T}
        new{T,auto_cast}(storage, min_count, auto_cast)
    end

    function Buffer{T}(storage::Vector{T}; min_count=0, auto_cast::Bool=false) where {T}
        new{T,auto_cast}(storage, min_count, auto_cast)
    end
end

@inline function (op::Buffer{T,false})(executor, value::T) where {T}
    push!(op.buffer, value)
    nothing
end

@inline function (op::Buffer{T,true})(executor, value) where {T}
    push!(op.buffer, T(value)) # try to cast
    nothing
end

@inline is_valid(op::Buffer) = length(op.buffer) >= op.min_count

@inline get_state(op::Buffer) = op.buffer

@inline Base.empty!(op::Buffer) = empty!(op.buffer)
