"""
This operation does nothing. It is useful for testing purposes.
"""
struct OpNone{Next<:Union{Nothing,Op}} <: Op
    next::Next
    
    OpNone() = new{Nothing}(nothing)
    OpNone(::Next) where {Next<:Op} = new{Nothing}(nothing) # Next is ignored
end

@inline (op::OpNone)(_) = nothing
