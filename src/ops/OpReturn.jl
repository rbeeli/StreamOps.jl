"""
Returns passed value.
Calls next operation in pipeline if there is one.
Always returns passed value.
"""
struct OpReturn{Next<:Union{Nothing,Op}} <: Op
    next::Next
    
    OpReturn() = new{Nothing}(nothing)
    OpReturn(next::Next) where {Next<:Union{Nothing,Op}} = new{Next}(next)
end

@inline (op::OpReturn)(value) = begin
    !isnothing(op.next) && op.next(value)
    value
end
