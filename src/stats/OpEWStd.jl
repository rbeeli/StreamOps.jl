"""
Expontential Weighted Moving Standard Deviation with bias correction.

References
----------
Incremental calculation of weighted mean and variance, Tony Finch, Feb 2009
https://blog.fugue88.ws/archives/2017-01/The-correct-way-to-start-an-Exponential-Moving-Average-EMA
https://github.com/pandas-dev/pandas/blob/main/pandas/_libs/window/aggregations.pyx#L1877
"""
mutable struct OpEWStd{In<:Number,Out<:Number,Next<:Op} <: Op
    const next::Next
    const alpha::Out
    const corrected::Bool # bias correction
    sum_wt::Out
    sum_wt2::Out
    old_wt::Out
    mean::Out
    var::Out
    initialized::Bool

    OpEWStd{In}(
        alpha::Out
        ;
        corrected::Bool=true,
        next::Next=OpNone()
    ) where {In<:Number,Out<:Number,Next<:Op} =
        new{In,Out,Next}(
            next,
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

@inline (op::OpEWStd{In,Out})(value::In) where {In<:Number,Out<:Number} = begin
    if !op.initialized
        op.mean = value
        std = op.corrected ? NaN : zero(Out)
        op.initialized = true
        op.next(std)
    else
        # static
        old_wt_factor = one(Out) - op.alpha
        new_wt = op.corrected ? one(Out) : op.alpha

        op.sum_wt *= old_wt_factor
        op.sum_wt2 *= old_wt_factor * old_wt_factor
        op.old_wt *= old_wt_factor

        # mean update
        old_mean = op.mean
        if op.mean != value # reduce numerical errors
            op.mean = ((op.old_wt * old_mean) + (new_wt * value)) / (op.old_wt + new_wt)
        end

        # variance update
        op.var = (
            (op.old_wt * (op.var + ((old_mean - op.mean) * (old_mean - op.mean)))) +
            (new_wt * ((value - op.mean) * (value - op.mean)))
        ) / (op.old_wt + new_wt)

        op.sum_wt += new_wt
        op.sum_wt2 += (new_wt * new_wt)
        op.old_wt += new_wt

        if op.corrected
            num = op.sum_wt * op.sum_wt
            denom = num - op.sum_wt2
            if denom > 0
                bias = num / denom
                op.next(sqrt(bias * op.var))
            else
                op.next(Out(NaN))
            end
        else
            op.sum_wt /= op.old_wt
            op.sum_wt2 /= op.old_wt * op.old_wt
            op.old_wt = one(Out)

            op.next(sqrt(op.var))
        end
    end
end
