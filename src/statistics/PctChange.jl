"""
Calculates percentage change of two numeric values.
The input must be an iterable, where the first value represents
`x\\_{t-1}`, and the second value represents `x\\_t`.

Formula
=======

`` y = x\\_t / x\\_{t-1} - 1 ``
"""
mutable struct PctChange{In<:Number,Out<:Number} <: StreamOperation
    current::Tuple{In,In}
    called::Bool

    PctChange{In,Out}(
        ;
        init=(zero(In), zero(In))
    ) where {In<:Number,Out<:Number} =
        new{In,Out}((init[1], init[2]), false)
end

@inline function (op::PctChange)(executor, value)
    op.current = (first(value), last(value))
    op.called = true
    nothing
end

@inline is_valid(op::PctChange) = op.called

@inline function get_state(op::PctChange{In,Out})::Out where {In,Out}
    last(op.current) / first(op.current) - one(Out)
end
