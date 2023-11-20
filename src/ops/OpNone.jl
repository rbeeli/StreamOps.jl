"""
This operation does nothing. It is useful for testing purposes.
"""
struct OpNone <: Op
    OpNone(; next=nothing) = new() # Next is ignored
end

@inline (op::OpNone)(_) = nothing
