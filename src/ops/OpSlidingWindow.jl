using DataStructures


"""
Maintains a sliding window of the last `window_size` values
and passes the window to the next operation.
"""
struct OpSlidingWindow{In,Next<:Op} <: Op
    next::Next
    buffer::CircularBuffer{In}

    # zero for default value does not work on strings, use one instead
    OpSlidingWindow{In}(window_size::Int, next::Next; init_value=one(t)) where {In<:AbstractString,Next<:Op} = begin
        buffer = CircularBuffer{In}(window_size)
        fill!(buffer, init_value)
        new{In,Next}(next, buffer)
    end
    OpSlidingWindow{In}(window_size::Int, next::Next; init_value=zero(t)) where {In,Next<:Op} = begin
        buffer = CircularBuffer{In}(window_size)
        fill!(buffer, init_value)
        new{In,Next}(next, buffer)
    end
end

@inline (op::OpSlidingWindow)(value) = begin
    # automatically handles overwriting in a circular manner
    push!(op.buffer, value)
    op.next(view(op.buffer, 1:length(op.buffer)))
end
