"""
Z-Score based on exponentially weighted moving average and standard deviation.

Formula
-------

    z = (x - μ) / σ

"""
struct EWZScore{In<:Number,Out<:Number}
    ew_mean::EWMean{In,Out}
    ew_std::EWStd{In,Out}
    corrected::Bool # bias correction for both mean and std

    EWZScore{In}(
        alpha::Out
        ;
        corrected=true
    ) where {In<:Number,Out<:Number} =
        new{In,Out}(
            EWMean{In}(alpha; corrected=corrected),
            EWStd{In}(alpha; corrected=corrected),
            corrected
        )
end

@inline (state::EWZScore{In})(value::In) where {In<:Number} = begin
    mean = state.ew_mean(value)
    std = state.ew_std(value)
    (value - mean) / std
end
