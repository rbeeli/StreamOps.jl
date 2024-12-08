"""
Calculates the percentage change of consecutive values.

# Formula
`` y = x\\_t / x\\_{t-1} - 1 ``
"""
mutable struct PctChange{In<:Number,Out<:Number} <: StreamOperation
    current::In
    prev::In
    counter::Int
    const min_count::Int

    PctChange{In,Out}(
        ;
        init=zero(In),
        min_count::Int=2
    ) where {In<:Number,Out<:Number} =
        new{In,Out}(init, init, 0, min_count)
end

@inline function (op::PctChange)(executor, value)
    op.prev = op.current
    op.current = value
    op.counter += 1
    nothing
end

@inline is_valid(op::PctChange) = op.counter >= op.min_count

@inline function get_state(op::PctChange{In,Out})::Out where {In,Out}
    op.current / op.prev - one(Out)
end
