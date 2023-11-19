"""
Rolling Z-Score based on rolling arithmetic moving average and standard deviation.

Formula
-------

    z = (x - μ) / σ

"""
mutable struct OpZScore{In<:Number,Out<:Number,Next<:Op} <: Op
    const next::Next
    const mean::OpMean{In,Out,OpReturn{Nothing}}
    const std::OpStd{In,Out,OpReturn{Nothing}}
    const corrected::Bool # bias correction for std

    OpZScore{In,Out}(window_size::Int, next::Next; corrected=true) where {In<:Number,Out<:Number,Next<:Op} =
        new{In,Out,Next}(
            next,
            OpMean{In,Out}(window_size, OpReturn()),
            OpStd{In,Out}(window_size, OpReturn(); corrected=corrected),
            corrected
        )
end

@inline (op::OpZScore{In})(value::In) where {In<:Number} = begin
    mean = op.mean(value)
    std = op.std(value)
    z_score = (value - mean) / std
    op.next(z_score)
end
