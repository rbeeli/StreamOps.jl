"""
Calculates the expontentially weighted moving average (EWMA) with bias correction.

The parameter `alpha` is the weight of the new value, and should be in the range [0, 1].
A higher alpha value discounts older observations faster,
hence the model is more reactive to recent changes.

# Formulas

    corrected = true:

        S_t = [ (1 - alpha) * S_{t-1} + alpha * X_t ] / (1 - (1-alpha)^t)

    corrected = false:

        S_0 = X_0
        S_t = (1 - alpha) * S_{t-1} + alpha * X_t

# References
Incremental calculation of weighted mean and variance, Tony Finch, Feb 2009
https://blog.fugue88.ws/archives/2017-01/The-correct-way-to-start-an-Exponential-Moving-Average-EMA
"""
mutable struct EWMean{In<:Number,Out<:Number,corrected} <: StreamOperation
    const alpha::Out
    const c::Out # 1 - alpha
    const corrected::Bool # bias correction
    M::Out
    ci::Out
    n::Int

    EWMean{In,Out}(
        ;
        alpha::Out,
        corrected=true
    ) where {In<:Number,Out<:Number} =
        new{In,Out,corrected}(
            alpha,
            one(Out) - alpha, # c
            corrected,
            zero(Out), # M
            corrected ? one(Out) : zero(Out), # ci
            0 # n
        )
end

# uncorrected mean
@inline function (op::EWMean{In,Out,false})(executor, value::In) where {In,Out}
    if op.n == 0
        op.M = value
    else
        op.M = op.c * op.M + op.alpha * value
    end

    op.n += 1

    nothing
end

# bias corrected mean
@inline function (op::EWMean{In,Out,true})(executor, value::In) where {In,Out}
    op.M = op.c * op.M + op.alpha * value
    op.n += 1
    op.ci *= op.c
    nothing
end

@inline function is_valid(op::EWMean)
    op.n > 0
end

# uncorrected mean
@inline function get_state(op::EWMean{In,Out,false})::Out where {In,Out}
    op.M
end

# bias corrected mean
@inline function get_state(op::EWMean{In,Out,true})::Out where {In,Out}
    op.M / (one(Out) - op.ci)
end
