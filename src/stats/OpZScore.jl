"""
Rolling Z-Score based on rolling arithmetic moving average and standard deviation.

Formula
-------

    z = (x - μ) / σ

"""
mutable struct OpZScore{In<:Number,Out<:Number,Next<:Op} <: Op
    const next::Next
    const mean::OpMean{In,Out,OpReturn{OpNone}}
    const std::OpStd{In,Out,OpReturn{OpNone}}
    const corrected::Bool # bias correction for std

    OpZScore{In,Out}(
        window_size::Int
        ;
        corrected=true,
        next::Next=OpNone()
    ) where {In<:Number,Out<:Number,Next<:Op} =
        new{In,Out,Next}(
            next,
            OpMean{In,Out}(window_size; next=OpReturn()),
            OpStd{In,Out}(window_size; corrected=corrected, next=OpReturn()),
            corrected
        )
end

@inline (op::OpZScore{In})(value::In) where {In<:Number} = begin
    mean = op.mean(value)
    std = op.std(value)
    z_score = (value - mean) / std
    op.next(z_score)
end
