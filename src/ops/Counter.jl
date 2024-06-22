"""
Counts the number of times it is called and returns the count.
"""
mutable struct Counter
    counter::Int
    Counter() = new(zero(Int))
    Counter(init_value::Int) = new(init_value)
end

@inline (op::Counter)(value) = begin
    op.counter += 1
    op.counter
end
