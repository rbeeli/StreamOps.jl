"""
Expontential Weighted Moving Average (EWMA) with bias correction.

Formulas
--------

    corrected = true:

        S_t = [ (1 - alpha) * S_{t-1} + alpha * X_t ] / (1 - (1-alpha)^t)

    corrected = false:

        S_0 = X_0
        S_t = (1 - alpha) * S_{t-1} + alpha * X_t

References
----------
Incremental calculation of weighted mean and variance, Tony Finch, Feb 2009
https://blog.fugue88.ws/archives/2017-01/The-correct-way-to-start-an-Exponential-Moving-Average-EMA
"""
mutable struct EWMean{In<:Number,Out<:Number}
    const alpha::Out
    const corrected::Bool # bias correction
    M::Out
    extra::Out
    extra_factor::Out
    n::Int

    EWMean{In}(
        ;
        alpha::Out,
        corrected=true
    ) where {In<:Number,Out<:Number} =
        new{In,Out}(
            alpha,
            corrected,
            zero(Out), # M
            one(Out), # extra
            corrected ? one(Out) - alpha : zero(Out), # extra_factor
            0 # n
        )
end

@inline function (state::EWMean{In,Out})(value::In)::Out where {In<:Number,Out<:Number}
    if !state.corrected && state.n == 0
        state.M = value
    else
        state.M = (one(Out) - state.alpha) * state.M + state.alpha * value
    end
    mean = state.M
    state.extra *= state.extra_factor # only relevant if corrected=true
    mean /= one(Out) - state.extra
    state.n += 1
    mean
end
