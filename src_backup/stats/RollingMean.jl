using DataStructures


"""
Calculates the moving average with fixed window size in O(1) time.
"""
mutable struct RollingMean{In<:Number,Out<:Number}
    const buffer::CircularBuffer{In}
    const window_size::Int
    M1::Out

    RollingMean{In,Out}(
        window_size::Int
    ) where {In<:Number,Out<:Number} =
        new{In,Out}(
            CircularBuffer{In}(window_size),
            window_size,
            zero(Out) # M1
        )
end

@inline (op::RollingMean{In})(value::In) where {In<:Number} = begin
    if isfull(op.buffer)
        op.M1 -= op.buffer[1]
    end
    push!(op.buffer, value)
    op.M1 += value
    op.M1 / length(op.buffer)
end
