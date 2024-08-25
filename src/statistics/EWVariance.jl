"""
Expontentially Weighted Moving Varianc with bias correction.

References
----------
Incremental calculation of weighted mean and variance, Tony Finch, Feb 2009
https://blog.fugue88.ws/archives/2017-01/The-correct-way-to-start-an-Exponential-Moving-Average-EMA
https://github.com/pandas-dev/pandas/blob/main/pandas/_libs/window/aggregations.pyx#L1877
"""
mutable struct EWVariance{In<:Number,Out<:Number,corrected} <: StreamOperation
    const alpha::Out
    const corrected::Bool # bias correction
    sum_wt::Out
    sum_wt2::Out
    old_wt::Out
    mean::Out
    var::Out
    nobs::Int
    EWVariance{In,Out}(
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
            0 # nobs
        )
end

# uncorrected variance
@inline function (op::EWVariance{In,Out,false})(executor, value::In) where {In<:Number,Out<:Number}
    op.nobs += 1
    if op.nobs == 1
        op.mean = value
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
end

# bias-corrected variance
@inline function (op::EWVariance{In,Out,true})(executor, value::In) where {In<:Number,Out<:Number}
    op.nobs += 1
    if op.nobs == 1
        op.mean = value
        return nothing
    end
    
    alpha = op.alpha
    old_wt_factor = one(Out) - alpha
    new_wt = one(Out)

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
end

@inline function is_valid(op::EWVariance)
    op.nobs > 0
end

# uncorrected variance
@inline function get_state(op::EWVariance{In,Out,false})::Out where {In,Out}
    op.nobs > 1 ? op.var : zero(Out)
end

# bias corrected variance
@inline function get_state(op::EWVariance{In,Out,true})::Out where {In,Out}
    if op.nobs > 1
        num = op.sum_wt * op.sum_wt
        denom = num - op.sum_wt2
        if denom > 0
            return (num / denom) * op.var
        end
    end
    return Out(NaN)
end
