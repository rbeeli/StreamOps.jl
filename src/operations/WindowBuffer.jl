using DataStructures

"""
Maintains a rolling window of the last `window_size` values using a circular buffer.

Note that the returned value is a view into the buffer, so it is not a copy of the data,
hence the result should not be modified or stored for later use.
If temporary storage of the result or modification of the values is needed, a copy should be made.
"""
mutable struct WindowBuffer{In} <: StreamOperation
    const buffer::CircularBuffer{In}
    counter::Int

    # special constructor for strings
    WindowBuffer{In}(
        window_size::Int
        ;
        init_value=one(In) # zero for default value does not work on strings, use one instead
    ) where {In<:AbstractString} = begin
        buffer = CircularBuffer{In}(window_size)
        fill!(buffer, init_value)
        new{In}(buffer, 0)
    end

    WindowBuffer{In}(
        window_size::Int
        ;
        init_value=zero(In)
    ) where {In} = begin
        buffer = CircularBuffer{In}(window_size)
        fill!(buffer, init_value)
        new{In}(buffer, 0)
    end
end

@inline function (op::WindowBuffer)(executor, value)
    # automatically handles overwriting in a circular manner
    push!(op.buffer, value)
    op.counter += 1
    nothing
end

@inline is_valid(op::WindowBuffer) = op.counter >= length(op.buffer)

@inline function get_state(op::WindowBuffer)
    view(op.buffer, :)
end
