"""
Represents a constant value that is passed through the stream.
"""
mutable struct Constant{T} <: StreamOperation
    const value::T
    
    Constant(value::T) where{T} = new{T}(value)
end

function reset!(op::Constant)
    nothing
end

# add default nothing to value since we don't need to bind an input value
@inline function(op::Constant)(executor, value=nothing)
    nothing
end

@inline is_valid(op::Constant) = true

@inline function get_state(op::Constant{T})::T where {T}
    op.value
end
