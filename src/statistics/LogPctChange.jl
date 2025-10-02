"""
Calculates the logarithmic percentage change of consecutive values.

# Formula
`` y = log(x\\_t / x\\_{t-1}) ``
"""
mutable struct LogPctChange{In<:Number,Out<:Number} <: StreamOperation
    const min_count::Int
    const init_current::In
    const init_pct_change::Out
    current::In
    pct_change::Out
    counter::Int

    function LogPctChange{In,Out}(;
        current=zero(In), pct_change=zero(Out), min_count::Int=2
    ) where {In<:Number,Out<:Number}
        new{In,Out}(
            min_count, # min_count
            current, # init_current
            pct_change, # init_pct_change
            current, # current
            pct_change, # pct_change
            0, # counter
        )
    end
end

operation_output_type(::LogPctChange{In,Out}) where {In,Out} = Out

function reset!(op::LogPctChange)
    op.current = op.init_current
    op.pct_change = op.init_pct_change
    op.counter = 0
    nothing
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

export LogPctChange
