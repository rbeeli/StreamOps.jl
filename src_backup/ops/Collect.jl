"""
Collects all passed values to this operation by appending them to a vector.
The storage vector can be passed as the first argument to the operation.
If no vector is passed, a new vector is created.

The operation returns the passed value.

Note: This operation is almost identical to `Sink`, but returns the
passed value instead of the storage vector.
"""
struct Collect{E}
    buffer::Vector{E}
    Collect{E}(buffer=E[]) where {E} = new{E}(buffer)
    Collect(buffer) = new{eltype(buffer)}(buffer)
end

@inline (op::Collect)(value) = begin
    push!(op.buffer, value)
    value
end
