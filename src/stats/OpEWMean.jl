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
mutable struct OpEWMean{In<:Number,Out<:Number,Next<:Op} <: Op
    const next::Next
    const alpha::Out
    const corrected::Bool # bias correction
    M::Out
    extra::Out
    extra_factor::Out
    n::Int

    OpEWMean{In}(
        alpha::Out
        ;
        corrected=true,
        next::Next=OpNone()
    ) where {In<:Number,Out<:Number,Next<:Op} =
        new{In,Out,Next}(
            next,
            alpha,
            corrected,
            zero(Out), # M
            one(Out), # extra
            corrected ? one(Out) - alpha : zero(Out), # extra_factor
            0 # n
        )
end

@inline (op::OpEWMean{In,Out})(value::In) where {In<:Number,Out<:Number} = begin
    if !op.corrected && op.n == 0
        op.M = value
    else
        op.M = (one(Out) - op.alpha) * op.M + op.alpha * value
    end
    mean = op.M
    op.extra *= op.extra_factor # only relevant if corrected=true
    mean /= one(Out) - op.extra
    op.n += 1
    op.next(mean)
end
