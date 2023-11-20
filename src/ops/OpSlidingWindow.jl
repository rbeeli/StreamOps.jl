using DataStructures


"""
Maintains a sliding window of the last `window_size` values
and passes the window to the next operation.
"""
struct OpSlidingWindow{In,Next<:Op} <: Op
    next::Next
    buffer::CircularBuffer{In}


    OpSlidingWindow{In}(
        window_size::Int
        ;
        init_value=one(In), # zero for default value does not work on strings, use one instead
        next::Next=OpNone()
    ) where {In<:AbstractString,Next<:Op} = begin
        buffer = CircularBuffer{In}(window_size)
        fill!(buffer, init_value)
        new{In,Next}(next, buffer)
    end

    OpSlidingWindow{In}(
        window_size::Int
        ;
        init_value=zero(In),
        next::Next=OpNone()
    ) where {In,Next<:Op} = begin
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
