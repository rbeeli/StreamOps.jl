using DataStructures


"""
Rolling arithmetic average with fixed window size.
"""
mutable struct OpMean{In<:Number,Out<:Number,Next<:Op} <: Op
    const next::Next
    const buffer::CircularBuffer{In}
    const window_size::Int
    M1::Out

    OpMean{In,Out}(
        window_size::Int;
        next::Next=OpNone()
    ) where {In<:Number,Out<:Number,Next<:Op} =
        new{In,Out,Next}(
            next,
            CircularBuffer{In}(window_size),
            window_size,
            zero(Out) # M1
        )
end

@inline (op::OpMean{In})(value::In) where {In<:Number} = begin
    if isfull(op.buffer)
        op.M1 -= op.buffer[1]
    end
    push!(op.buffer, value)
    op.M1 += value
    mean = op.M1 / length(op.buffer)
    op.next(mean)
end
