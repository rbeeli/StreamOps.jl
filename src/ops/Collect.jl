"""
Collects all passed values to this operation by appending them to a vector.
The vector to append to must be passed as the first argument to the operation.
"""
struct Collect{E}
    out::Vector{E}

    Collect{E}(
        out::Vector{E}=E[]
    ) where {E} = new{E}(out)

    Collect(
        out::Vector{E}
    ) where {E} = new{E}(out)
end

@inline (op::Collect)(value) = begin
    push!(op.out, value)
    op.out
end
