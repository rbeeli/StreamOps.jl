"""
Represents a constant value that is passed through the stream.
"""
mutable struct Constant{T} <: StreamOperation
    value::T
    
    Constant(value::T) where{T} = new{T}(value)
end

@inline function(op::Constant)(executor, value)
    nothing
end

@inline is_valid(op::Constant) = true

@inline function get_state(op::Constant{T})::T where {T}
    op.value
end

@inline function reset!(op::Constant{T}) where {T}
    nothing
end
