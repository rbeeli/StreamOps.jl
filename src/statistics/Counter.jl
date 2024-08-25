"""
    Counter{T}

A counter of type `T` that increments by one each time it is called.
"""
mutable struct Counter{T} <: StreamOperation
    counter::T
    
    Counter(start::T=0) where{T} = new{T}(start)
    Counter{T}() where{T} = new{T}(zero(T))
end

@inline function(op::Counter{T})(args...) where {T}
    op.counter += one(T)
    nothing
end

@inline is_valid(op::Counter) = true

@inline function get_state(op::Counter{T})::T where {T}
    op.counter
end
