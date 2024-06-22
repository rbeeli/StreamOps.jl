using DataStructures

"""
Maintains a sliding window of the last `window_size` values using a circular buffer.
Note that the returned value is a view into the buffer, so it is not a copy of the data,
hence the result should not be modified or stored for later use.
If temporary storage of the result or modification is required, a copy should be made.
"""
struct RollingWindow{In}
    buffer::CircularBuffer{In}

    RollingWindow{In}(
        window_size::Int
        ;
        init_value=one(In) # zero for default value does not work on strings, use one instead
    ) where {In<:AbstractString} = begin
        buffer = CircularBuffer{In}(window_size)
        fill!(buffer, init_value)
        new{In}(buffer)
    end

    RollingWindow{In}(
        window_size::Int
        ;
        init_value=zero(In)
    ) where {In} = begin
        buffer = CircularBuffer{In}(window_size)
        fill!(buffer, init_value)
        new{In}(buffer)
    end
end

@inline (op::RollingWindow)(value) = begin
    # automatically handles overwriting in a circular manner
    push!(op.buffer, value)
    view(op.buffer, 1:length(op.buffer))
end
