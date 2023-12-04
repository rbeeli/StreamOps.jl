using DataStructures


"""
Maintains a sliding window of the last `window_size` values.
"""
struct SlidingWindow{In}
    buffer::CircularBuffer{In}

    SlidingWindow{In}(
        window_size::Int
        ;
        init_value=one(In) # zero for default value does not work on strings, use one instead
    ) where {In<:AbstractString} = begin
        buffer = CircularBuffer{In}(window_size)
        fill!(buffer, init_value)
        new{In}(buffer)
    end

    SlidingWindow{In}(
        window_size::Int
        ;
        init_value=zero(In)
    ) where {In} = begin
        buffer = CircularBuffer{In}(window_size)
        fill!(buffer, init_value)
        new{In}(buffer)
    end
end

@inline (state::SlidingWindow)(value) = begin
    # automatically handles overwriting in a circular manner
    push!(state.buffer, value)
    view(state.buffer, 1:length(state.buffer))
end
