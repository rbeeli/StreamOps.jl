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
mutable struct TimeTupleBuffer{TTime,TValue} <: StreamOperation
    const buffer::Vector{Tuple{TTime,TValue}}
    const min_count::Int

    function TimeTupleBuffer{TTime,TValue}(; min_count=0) where {TTime,TValue}
        new{TTime,TValue}(Tuple{TTime,TValue}[], min_count)
    end

    function TimeTupleBuffer(storage::Vector{Tuple{TTime,TValue}}; min_count=0) where {TTime,TValue}
        new{TTime,TValue}(storage, min_count)
    end
end

function reset!(op::TimeTupleBuffer)
    empty!(op.buffer)
    nothing
end

@inline function (op::TimeTupleBuffer{TTime,TValue})(executor, val::TValue) where {TTime,TValue}
    push!(op.buffer, (time(executor), val))
    nothing
end

@inline is_valid(op::TimeTupleBuffer) = length(op.buffer) >= op.min_count

@inline get_state(op::TimeTupleBuffer) = op.buffer

export TimeTupleBuffer
