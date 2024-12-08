"""
Calculates the logarithmic percentage change of consecutive values.

# Formula
`` y = log(x\\_t / x\\_{t-1}) ``
"""
mutable struct LogPctChange{In<:Number,Out<:Number} <: StreamOperation
    current::In
    pct_change::Out
    counter::Int
    const min_count::Int

    function LogPctChange{In,Out}(
        ;
        current=zero(In),
        pct_change=zero(Out),
        min_count::Int=2
    ) where {In<:Number,Out<:Number}
        new{In,Out}(current, pct_change, 0, min_count)
    end
end

@inline function (op::LogPctChange{In,Out})(executor, value::In) where {In,Out}
    if op.counter > 0
        op.pct_change = log(value / op.current)
    end
    op.current = value
    op.counter += 1
    nothing
end

@inline is_valid(op::LogPctChange) = op.counter >= op.min_count

@inline get_state(op::LogPctChange) = op.pct_change
