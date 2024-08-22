"""
Calculates difference of two numeric values.
The input must be an iterable, where the first value represents
`x\\_{t-1}`, and the second value represents `x\\_t`.

Formula
=======

`` y = x\\_t -/ x\\_{t-1} ``
"""
mutable struct Diff{T<:Number} <: StreamOperation
    current::Tuple{T,T}
    called::Bool

    function Diff{T}(
        ;
        init=(zero(T), zero(T))
    ) where {T<:Number}
        new{T}((init[1], init[2]), false)
    end
end

@inline function (op::Diff)(executor, value)
    op.current = (first(value), last(value))
    op.called = true
    nothing
end

@inline is_valid(op::Diff) = op.called

@inline function get_state(op::Diff{T})::T where {T}
    last(op.current) - first(op.current)
end
