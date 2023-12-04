"""
Rolling Z-Score based on rolling arithmetic moving average and standard deviation.

Formula
-------

    z = (x - μ) / σ

"""
struct ZScore{In<:Number,Out<:Number}
    mean::Mean{In,Out}
    std::Std{In,Out}
    corrected::Bool # bias correction for std

    ZScore{In,Out}(
        window_size::Int
        ;
        corrected=true
    ) where {In<:Number,Out<:Number} =
        new{In,Out}(
            Mean{In,Out}(window_size),
            Std{In,Out}(window_size; corrected=corrected),
            corrected
        )
end

@inline (state::ZScore{In})(value::In) where {In<:Number} = begin
    mean = state.mean(value)
    std = state.std(value)
    (value - mean) / std
end
