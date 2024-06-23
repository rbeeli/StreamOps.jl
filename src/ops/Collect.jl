"""
Collects all passed values to this operation by appending them to a vector.
The vector to append to must be passed as the first argument to the operation.
"""
struct Collect{E}
    buffer::Vector{E}
    Collect{E}(buffer=E[]) where {E} = new{E}(buffer)
    Collect(buffer) = new{eltype(buffer)}(buffer)
end

@inline (op::Collect)(value) = begin
    push!(op.buffer, value)
    op.buffer
end
