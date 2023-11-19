"""
Z-Score based on exponentially weighted moving average and standard deviation.

Formula
-------

    z = (x - μ) / σ

"""
mutable struct OpEWZScore{In<:Number,Out<:Number,Next<:Op} <: Op
    const next::Next
    const ew_mean::OpEWMean{In,Out,OpReturn{Nothing}}
    const ew_std::OpEWStd{In,Out,OpReturn{Nothing}}
    const corrected::Bool # bias correction for both mean and std

    OpEWZScore{In}(alpha::Out, next::Next; corrected=true) where {In<:Number,Out<:Number,Next<:Op} =
        new{In,Out,Next}(
            next,
            OpEWMean{In}(alpha, OpReturn(); corrected=corrected),
            OpEWStd{In}(alpha, OpReturn(); corrected=corrected),
            corrected
        )
end

@inline (op::OpEWZScore{In})(value::In) where {In<:Number} = begin
    mean = op.ew_mean(value)
    std = op.ew_std(value)
    z_score = (value - mean) / std
    op.next(z_score)
end
