using DataStructures


"""
Rolling arithmetic average with fixed window size.
"""
mutable struct Mean{In<:Number,Out<:Number}
    const buffer::CircularBuffer{In}
    const window_size::Int
    M1::Out

    Mean{In,Out}(
        window_size::Int
    ) where {In<:Number,Out<:Number} =
        new{In,Out}(
            CircularBuffer{In}(window_size),
            window_size,
            zero(Out) # M1
        )
end

@inline (state::Mean{In})(value::In) where {In<:Number} = begin
    if isfull(state.buffer)
        state.M1 -= state.buffer[1]
    end
    push!(state.buffer, value)
    state.M1 += value
    state.M1 / length(state.buffer)
end
