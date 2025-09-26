using DataStructures

"""
A circular buffer operation that maintains a fixed buffer of length `size`.
Once the buffer is full, the oldest element is overwritten (FIFO).

A minimum count can be specified which marks
this operation as valid only when the buffer has at least
`min_count` many values.

The implementation is based on [DataStructures.jl](https://juliacollections.github.io/DataStructures.jl/latest/)'s [CircularBuffer](https://juliacollections.github.io/DataStructures.jl/latest/circ_buffer/).

The output type of `get_state` implements `AbstractVector{T}`.

# Arguments
- `min_count=0`: The minimum number of values required in the buffer to be considered valid.
"""
mutable struct RingBuffer{T} <: StreamOperation
    const buffer::CircularBuffer{T}
    const min_count::Int

    function RingBuffer{T}(size; min_count=0) where {T}
        new{T}(CircularBuffer{T}(size), min_count)
    end
end

function reset!(op::RingBuffer)
    empty!(op.buffer)
    nothing
end

@inline function (op::RingBuffer{T})(executor, value::T) where {T}
    push!(op.buffer, value)
    nothing
end

@inline is_valid(op::RingBuffer) = length(op.buffer) >= op.min_count

@inline get_state(op::RingBuffer) = op.buffer

@inline Base.length(op::RingBuffer) = length(op.buffer)

export RingBuffer, is_valid, get_state, reset!
