using DataStructures

"""
Calculates the simple moving average with fixed window size.
Implementation uses O(1) time complexity, and O(n) space complexity algorithm.
"""
mutable struct Mean{In<:Number,Out<:Number} <: StreamOperation
    const buffer::CircularBuffer{In}
    const window_size::Int
    const full_only::Bool
    M1::Out

    function Mean{In,Out}(
        window_size::Int
        ;
        full_only::Bool=false
    ) where {In<:Number,Out<:Number}
        @assert window_size > 0 "Window size must be greater than 0"
        new{In,Out}(
            CircularBuffer{In}(window_size),
            window_size,
            full_only,
            zero(Out), # M1
        )
    end
end

@inline (op::Mean{In})(executor, value::In) where {In<:Number} = begin
    if isfull(op.buffer)
        op.M1 -= @inbounds op.buffer[1]
    end
    push!(op.buffer, value)
    op.M1 += value
    nothing
end

@inline function is_valid(op::Mean)
    # TODO: Use type arguments and dispatch to avoid branching?
    op.full_only && return isfull(op.buffer)
    return !isempty(op.buffer)
end

@inline function get_state(op::Mean{In,Out})::Out where {In,Out}
    op.M1 / length(op.buffer)
end
