using DataStructures: CircularBuffer

"""
Calculates the simple moving average with fixed window size.
Implementation uses O(1) time complexity, and O(n) space complexity algorithm.
"""
mutable struct Mean{In<:Number,Out<:Number,full_only} <: StreamOperation
    const full_only::Bool
    const buffer::CircularBuffer{In}
    const window_size::Int
    M1::Out

    function Mean{In,Out}(window_size::Int; full_only::Bool=false) where {In<:Number,Out<:Number}
        @assert window_size > 0 "Window size must be greater than 0"
        new{In,Out,full_only}(
            full_only,
            CircularBuffer{In}(window_size),
            window_size,
            zero(Out), # M1
        )
    end
end

operation_output_type(::Mean{In,Out,full_only}) where {In,Out,full_only} = Out

function reset!(op::Mean{In,Out,full_only}) where {In,Out,full_only}
    empty!(op.buffer)
    op.M1 = zero(Out)
    nothing
end

@inline function (op::Mean{In})(executor, value::In) where {In<:Number}
    if isfull(op.buffer)
        op.M1 -= @inbounds first(op.buffer)
    end
    push!(op.buffer, value)
    op.M1 += value
    nothing
end

# mean valid with 1 or more observations
@inline function is_valid(op::Mean{In,Out,false}) where {In,Out}
    !isempty(op.buffer)
end

# full only mode: mean valid with exactly window_size observations
@inline function is_valid(op::Mean{In,Out,true}) where {In,Out}
    isfull(op.buffer)
end

@inline function get_state(op::Mean{In,Out})::Out where {In,Out}
    op.M1 / length(op.buffer)
end

export Mean
