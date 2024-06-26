"""
Collects all passed values to this operation by appending them to a vector.
The storage vector can be passed as the first argument to the operation.
If no vector is passed, a new vector is created.

The operation returns the storage vector.

Note: This operation is almost identical to `Collect`, but returns the
storage vector instead of the passed value.
"""
struct Sink{E}
    buffer::Vector{E}
    Sink{E}(buffer=E[]) where {E} = new{E}(buffer)
    Sink(buffer) = new{eltype(buffer)}(buffer)
end

@inline (op::Sink)(value) = begin
    push!(op.buffer, value)
    op.buffer
end
