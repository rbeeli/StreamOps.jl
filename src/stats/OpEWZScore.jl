"""
Z-Score based on exponentially weighted moving average and standard deviation.

Formula
-------

    z = (x - μ) / σ

"""
mutable struct OpEWZScore{In<:Number,Out<:Number,Next<:Op} <: Op
    const next::Next
    const ew_mean::OpEWMean{In,Out,OpReturn{OpNone}}
    const ew_std::OpEWStd{In,Out,OpReturn{OpNone}}
    const corrected::Bool # bias correction for both mean and std

    OpEWZScore{In}(
        alpha::Out
        ;
        corrected=true,
        next::Next=OpNone()
    ) where {In<:Number,Out<:Number,Next<:Op} =
        new{In,Out,Next}(
            next,
            OpEWMean{In}(alpha; corrected=corrected, next=OpReturn()),
            OpEWStd{In}(alpha; corrected=corrected, next=OpReturn()),
            corrected
        )
end

@inline (op::OpEWZScore{In})(value::In) where {In<:Number} = begin
    mean = op.ew_mean(value)
    std = op.ew_std(value)
    z_score = (value - mean) / std
    op.next(z_score)
end
