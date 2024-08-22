"""
Calculates the moving Z-Score with fixed window size in O(1) time.

Formula
-------

    z = (x - μ) / σ

"""
struct RollingZScore{In<:Number,Out<:Number}
    mean::RollingMean{In,Out}
    std::RollingStd{In,Out}
    corrected::Bool # bias correction for std

    RollingZScore{In,Out}(
        window_size::Int
        ;
        corrected=true
    ) where {In<:Number,Out<:Number} =
        new{In,Out}(
            RollingMean{In,Out}(window_size),
            RollingStd{In,Out}(window_size; corrected=corrected),
            corrected
        )
end

@inline (op::RollingZScore{In})(value::In) where {In<:Number} = begin
    mean = op.mean(value)
    std = op.std(value)
    (value - mean) / std
end
