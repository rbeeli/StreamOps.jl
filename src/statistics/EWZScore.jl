"""
    ZScore{In<:Number,Out<:Number,corrected}

Calculates the expontentially weighted moving z-score with optional bias correction.
"""
mutable struct EWZScore{In<:Number,Out<:Number,corrected} <: StreamOperation
    const alpha::Out
    const corrected::Bool # bias correction
    sum_wt::Out
    sum_wt2::Out
    old_wt::Out
    mean::Out
    var::Out
    nobs::Int
    current_zscore::Out

    EWZScore{In,Out}(
        ;
        alpha::Out,
        corrected::Bool=true
    ) where {In<:Number,Out<:Number} =
        new{In,Out,corrected}(
            alpha,
            corrected,
            one(Out), # sum_wt
            one(Out), # sum_wt2
            one(Out), # old_wt
            zero(Out), # mean
            zero(Out), # var
            0, # nobs
            zero(Out) # current_zscore
        )
end

# uncorrected z-score
@inline function (op::EWZScore{In,Out,false})(executor, value::In) where {In<:Number,Out<:Number}
    op.nobs += 1
    if op.nobs == 1
        op.mean = value
        op.current_zscore = Out(NaN)
        return nothing
    end
    
    alpha = op.alpha
    old_wt_factor = one(Out) - alpha
    new_wt = alpha

    op.sum_wt *= old_wt_factor
    op.sum_wt2 *= old_wt_factor * old_wt_factor
    op.old_wt *= old_wt_factor

    old_mean = op.mean
    if op.mean != value # avoid numerical errors on constant series
        op.mean = (op.old_wt * old_mean + new_wt * value) / (op.old_wt + new_wt)
    end
    
    op.var = (op.old_wt * (op.var + (old_mean - op.mean) * (old_mean - op.mean)) +
              new_wt * (value - op.mean) * (value - op.mean)) / (op.old_wt + new_wt)

    op.sum_wt += new_wt
    op.sum_wt2 += new_wt * new_wt
    op.old_wt += new_wt

    op.sum_wt /= op.old_wt
    op.sum_wt2 /= op.old_wt * op.old_wt
    op.old_wt = one(Out)

    # Calculate z-score
    std_dev = sqrt(op.var)
    op.current_zscore = std_dev > zero(Out) ? (value - op.mean) / std_dev : Out(NaN)

    nothing
end

# bias-corrected z-score
@inline function (op::EWZScore{In,Out,true})(executor, value::In) where {In<:Number,Out<:Number}
    op.nobs += 1
    if op.nobs == 1
        op.mean = value
        op.sum_wt = op.alpha
        op.sum_wt2 = op.alpha * op.alpha
        op.current_zscore = Out(NaN)
        return nothing
    end
    
    alpha = op.alpha
    old_wt_factor = one(Out) - alpha
    new_wt = one(Out)

    op.sum_wt = alpha + old_wt_factor * op.sum_wt
    op.sum_wt2 = alpha * alpha + old_wt_factor * old_wt_factor * op.sum_wt2
    op.old_wt *= old_wt_factor

    old_mean = op.mean
    if op.mean != value # avoid numerical errors on constant series
        op.mean = (op.old_wt * old_mean + new_wt * value) / (op.old_wt + new_wt)
    end
    
    op.var = (op.old_wt * (op.var + (old_mean - op.mean) * (old_mean - op.mean)) +
              new_wt * (value - op.mean) * (value - op.mean)) / (op.old_wt + new_wt)

    op.old_wt += new_wt

    # Calculate bias-corrected variance
    num = op.sum_wt * op.sum_wt
    denom = num - op.sum_wt2
    corrected_var = denom > zero(Out) ? (num / denom) * op.var : op.var

    # Calculate z-score
    std_dev = sqrt(corrected_var)
    op.current_zscore = std_dev > zero(Out) ? (value - op.mean) / std_dev : Out(NaN)

    nothing
end

@inline function is_valid(op::EWZScore)
    op.nobs > 0
end

@inline function get_state(op::EWZScore{In,Out})::Out where {In,Out}
    op.current_zscore
end