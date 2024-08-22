"""
Calculates percentage change of two numeric values.
The input must be a tuple of two values: `(x\\_{t-1}, x\\_t)`.

Formula
=======

`` y = x\\_t / x\\_{t-1} - 1 ``
"""
mutable struct PctChange{In<:Number,Out<:Number} <: StreamOperation
    current::Tuple{In,In}
    called::Bool

    function PctChange{In,Out}(
        ;
        init=(zero(In), zero(In))
    ) where {In<:Number,Out<:Number}
        new{In,Out}((init[1], init[2]), false)
    end
end

@inline (op::PctChange)(executor, value) = begin
    op.current = (value[1], value[2])
    op.called = true
    nothing
end

@inline is_valid(op::PctChange) = op.called

@inline function get_state(op::PctChange{In,Out})::Out where {In,Out}
    op.current[2] / op.current[1] - one(Out)
end
