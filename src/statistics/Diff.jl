"""
Calculates difference of two numeric values.
The input must be a tuple of two values: `(x\\_{t-1}, x\\_t)`.

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

@inline (op::Diff)(executor, value) = begin
    op.current = (value[1], value[2])
    op.called = true
    nothing
end

@inline is_valid(op::Diff) = op.called

@inline function get_state(op::Diff{T})::T where {T}
    op.current[2] - op.current[1]
end
