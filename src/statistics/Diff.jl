"""
Calculates difference of consecutive numeric values.

# Formula
`` y = x\\_t -/ x\\_{t-1} ``
"""
mutable struct Diff{T<:Number} <: StreamOperation
    current::T
    prev::T
    counter::Int

    function Diff{T}(
        ;
        init=zero(T)
    ) where {T<:Number}
        new{T}(init, init, 0)
    end
end

@inline function (op::Diff)(executor, value)
    op.prev = op.current
    op.current = value
    op.counter += 1
    nothing
end

@inline is_valid(op::Diff) = op.counter > 1

@inline function get_state(op::Diff{T})::T where {T}
    op.current - op.prev
end
