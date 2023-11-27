"""
Collects all passed values to this operation in an array
called `out` (which can be passed in the constructor).
"""
struct OpCollect{E,Next<:Op} <: Op
    next::Next
    out::Vector{E}

    OpCollect{E}(
        ;
        out::Vector{E}=E[],
        next::Next=OpNone()) where {E,Next<:Op} = new{E,Next}(next, out)

    OpCollect(
        ;
        out::Vector{E},
        next::Next=OpNone()) where {E,Next<:Op} = new{E,Next}(next, out)
end

@inline (op::OpCollect)(value) = begin
    push!(op.out, value)
    op.next(value)
end
