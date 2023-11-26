"""
Collects all passed values to this operation in an array
called `values` (which can be passed in the constructor).
"""
struct OpCollect{E,Next<:Op} <: Op
    next::Next
    values::Vector{E}

    OpCollect{E}(
        ;
        values::Vector{E}=E[],
        next::Next=OpNone()) where {E,Next<:Op} = new{E,Next}(next, values)

    OpCollect(
        ;
        values::Vector{E},
        next::Next=OpNone()) where {E,Next<:Op} = new{E,Next}(next, values)
end

@inline (op::OpCollect)(value) = begin
    push!(op.values, value)
    op.next(value)
end
