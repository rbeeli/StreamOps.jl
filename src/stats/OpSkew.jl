using DataStructures
using StatsBase


"""
Rolling arithmetic skewness with fixed window size.

TODO: Make it an efficient online-algorithm like OpMean and OpStd.

https://web.archive.org/web/20181222175223/http://people.ds.cam.ac.uk/fanf2/hermes/doc/antiforgery/stats.pdf
"""
mutable struct OpSkew{In<:Number,Out<:Number,Next<:Op} <: Op
    const next::Next
    const buffer::CircularBuffer{In}
    const window_size::Int
    const corrected::Bool

    OpSkew{In,Out}(
        window_size::Int
        ;
        corrected::Bool=true,
        next::Next=OpNone()
    ) where {In<:Number,Out<:Number,Next<:Op} =
        new{In,Out,Next}(
            next,
            CircularBuffer{In}(window_size),
            window_size,
            corrected
        )
end

@inline (op::OpSkew{In})(value::In) where {In<:Number} = begin
    DataStructures.push!(op.buffer, value)
    skew = skewness(op.buffer)

    if op.corrected
        # adjust. for statistical bias
        n = length(op.buffer)
        skew *= (sqrt(n * (n - 1))) / (n - 2)
    end

    op.next(skew)
end
