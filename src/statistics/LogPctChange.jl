"""
Calculates the logarithmic percentage change of consecutive values.

# Formula
`` y = log(x\\_t / x\\_{t-1}) ``
"""
mutable struct LogPctChange{In<:Number,Out<:Number} <: StreamOperation
    current::In
    prev::In
    counter::Int
    const min_count::Int

    LogPctChange{In,Out}(
        ;
        init=zero(In),
        min_count::Int=2
    ) where {In<:Number,Out<:Number} =
        new{In,Out}(init, init, 0, min_count)
end

@inline function (op::LogPctChange)(executor, value)
    op.prev = op.current
    op.current = value
    op.counter += 1
    nothing
end

@inline is_valid(op::LogPctChange) = op.counter >= op.min_count

@inline function get_state(op::LogPctChange{In,Out})::Out where {In,Out}
    log(op.current / op.prev)
end
