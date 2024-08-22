"""
Counts the number of times it is called and returns the count.
"""
mutable struct Counter{T<:Real}
    counter::T
    Counter() = Counter{Int}()
    Counter{T}() where {T} = new{T}(zero(T))
    Counter(init_value::T) where {T} = new{T}(init_value)
end

@inline (op::Counter{T})(value) where {T} = begin
    op.counter += one(T)
    op.counter
end
