"""
Expontential Weighted Moving Standard Deviation with bias correction.

References
----------
Incremental calculation of weighted mean and variance, Tony Finch, Feb 2009
https://blog.fugue88.ws/archives/2017-01/The-correct-way-to-start-an-Exponential-Moving-Average-EMA
https://github.com/pandas-dev/pandas/blob/main/pandas/_libs/window/aggregations.pyx#L1877
"""
mutable struct EWStd{In<:Number,Out<:Number}
    const alpha::Out
    const corrected::Bool # bias correction
    sum_wt::Out
    sum_wt2::Out
    old_wt::Out
    mean::Out
    var::Out
    initialized::Bool

    EWStd{In}(
        ;
        alpha::Out,
        corrected::Bool=true
    ) where {In<:Number,Out<:Number} =
        new{In,Out}(
            alpha,
            corrected,
            one(Out), # sum_wt
            one(Out), # sum_wt2
            one(Out), # old_wt
            zero(Out), # mean
            zero(Out), # var
            false # initialized
        )
end

@inline (state::EWStd{In,Out})(value::In) where {In<:Number,Out<:Number} = begin
    if !state.initialized
        state.mean = value
        std = state.corrected ? NaN : zero(Out)
        state.initialized = true
        return std
    end
    
    # static
    old_wt_factor = one(Out) - state.alpha
    new_wt = state.corrected ? one(Out) : state.alpha

    state.sum_wt *= old_wt_factor
    state.sum_wt2 *= old_wt_factor * old_wt_factor
    state.old_wt *= old_wt_factor

    # mean update
    old_mean = state.mean
    if state.mean != value # reduce numerical errors
        state.mean = ((state.old_wt * old_mean) + (new_wt * value)) / (state.old_wt + new_wt)
    end

    # variance update
    state.var = (
        (state.old_wt * (state.var + ((old_mean - state.mean) * (old_mean - state.mean)))) +
        (new_wt * ((value - state.mean) * (value - state.mean)))
    ) / (state.old_wt + new_wt)

    state.sum_wt += new_wt
    state.sum_wt2 += (new_wt * new_wt)
    state.old_wt += new_wt

    if state.corrected
        num = state.sum_wt * state.sum_wt
        denom = num - state.sum_wt2
        if denom > 0
            bias = num / denom
            return sqrt(bias * state.var)
        else
            return Out(NaN)
        end
    else
        state.sum_wt /= state.old_wt
        state.sum_wt2 /= state.old_wt * state.old_wt
        state.old_wt = one(Out)

        return sqrt(state.var)
    end
end
