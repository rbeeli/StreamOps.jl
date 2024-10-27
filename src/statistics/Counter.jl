"""
A counter of type `T` that increments by one each time it is called.

Optionally, a `min_count` value can be specified from when onwards
this operation changes into the "valid" state. This is useful if
other operations need to first be called multiple times before downstream
operations can start processing, so this operation can be used to signal when
these operations are deemed ready and further processing can begin.
"""
mutable struct Counter{T} <: StreamOperation
    counter::T
    const min_count::T
    
    Counter(start::T=0; min_count::T=0) where{T} = new{T}(start, min_count)
    Counter{T}(; min_count::T=0) where{T} = new{T}(zero(T), min_count)
end

@inline function(op::Counter{T})(args...) where {T}
    op.counter += one(T)
    nothing
end

@inline is_valid(op::Counter) = op.counter >= op.min_count

@inline function get_state(op::Counter{T})::T where {T}
    op.counter
end

@inline function reset!(op::Counter{T}) where {T}
    op.counter = zero(T)
    nothing
end
