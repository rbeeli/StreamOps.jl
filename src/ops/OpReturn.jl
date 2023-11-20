"""
Calls next operation in pipeline, and always returns the passed value.
It does NOT return the value calculated from the downstream pipeline.
"""
struct OpReturn{Next<:Op} <: Op
    next::Next

    OpReturn(; next::Next=OpNone()) where {Next<:Op} = new{Next}(next)
end

@inline (op::OpReturn)(value) = begin
    op.next(value)
    value
end
