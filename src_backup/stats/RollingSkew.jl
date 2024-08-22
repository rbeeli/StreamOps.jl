using DataStructures
using StatsBase


"""
Rolling arithmetic skewness with fixed window size.

TODO: Make it an efficient online-algorithm like Mean and Std.

https://web.archive.org/web/20181222175223/http://people.ds.cam.ac.uk/fanf2/hermes/doc/antiforgery/stats.pdf
"""
struct RollingSkew{In<:Number,Out<:Number}
    buffer::CircularBuffer{In}
    window_size::Int
    corrected::Bool

    RollingSkew{In,Out}(
        window_size::Int
        ;
        corrected::Bool=true
    ) where {In<:Number,Out<:Number} =
        new{In,Out}(
            CircularBuffer{In}(window_size),
            window_size,
            corrected
        )
end

@inline (op::RollingSkew{In})(value::In) where {In<:Number} = begin
    DataStructures.push!(op.buffer, value)
    skew = skewness(op.buffer)

    if op.corrected
        # adjust. for statistical bias
        n = length(op.buffer)
        skew *= (sqrt(n * (n - 1))) / (n - 2)
    end

    skew
end
