"""
Calculates the percentage change of consecutive values.

# Formula
`` y = x\\_t / x\\_{t-1} - 1 ``
"""
mutable struct PctChange{In<:Number,Out<:Number} <: StreamOperation
    current::In
    pct_change::Out
    counter::Int
    const min_count::Int

    function PctChange{In,Out}(
        ;
        current=zero(In),
        pct_change=zero(Out),
        min_count::Int=2
    ) where {In<:Number,Out<:Number}
        new{In,Out}(current, pct_change, 0, min_count)
    end
end

@inline function (op::PctChange{In,Out})(executor, value::In) where {In,Out}
    if op.counter > 0
        op.pct_change = value / op.current - one(Out)
    end
    op.current = value
    op.counter += 1
    nothing
end

@inline is_valid(op::PctChange) = op.counter >= op.min_count

@inline get_state(op::PctChange) = op.pct_change
