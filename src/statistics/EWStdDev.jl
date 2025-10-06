"""
Calculates the expontentially weighted moving standard deviation with optional bias correction.

# Arguments
- `alpha::Out`: The weight of the new value, should be in the range [0, 1]. A new value has a weight of `alpha`, and the previous value has a weight of `1 - alpha`.
- `corrected::Bool=true`: Whether to use corrected (unbiased) standard deviation (default is true)

# References
Incremental calculation of weighted mean and variance, Tony Finch, Feb 2009
https://blog.fugue88.ws/archives/2017-01/The-correct-way-to-start-an-Exponential-Moving-Average-EMA
https://github.com/pandas-dev/pandas/blob/main/pandas/_libs/window/aggregations.pyx#L1877
"""
mutable struct EWStdDev{In<:Number,Out<:Number,corrected} <: StreamOperation
    const variance::EWVariance{In,Out,corrected}
    function EWStdDev{In,Out}(; alpha::Out, corrected::Bool=true) where {In<:Number,Out<:Number}
        new{In,Out,corrected}(EWVariance{In,Out}(alpha=alpha, corrected=corrected))
    end
end

operation_output_type(::EWStdDev{In,Out,corrected}) where {In,Out,corrected} = Out

function reset!(op::EWStdDev)
    reset!(op.variance)
end

@inline function (op::EWStdDev{In})(executor, value::In) where {In<:Number}
    op.variance(executor, value)
    nothing
end

@inline function is_valid(op::EWStdDev)
    is_valid(op.variance)
end

# uncorrected std. deviation
@inline function get_state(op::EWStdDev{In,Out,false})::Out where {In,Out}
    sqrt(max(zero(Out), get_state(op.variance)))
end

# bias corrected std. deviation
@inline function get_state(op::EWStdDev{In,Out,true})::Out where {In,Out}
    sqrt(max(zero(Out), get_state(op.variance)))
end

export EWStdDev
