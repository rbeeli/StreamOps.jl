using DataStructures: CircularBuffer, SortedDict

"""
Maintains the rolling maximum over a fixed-size window.
The implementation updates in ``O(\\log n)`` time and uses ``O(n)`` space.

NaN values are tracked separately to avoid ordering issues; if any NaN values
are present in the current window, the reported maximum is NaN.
"""
mutable struct Max{T<:Number} <: StreamOperation
    const buffer::CircularBuffer{T}
    const window_size::Int
    const counts::SortedDict{T,Int}
    nan_count::Int

    function Max{T}(window_size::Int) where {T<:Number}
        window_size >= 1 || throw(ArgumentError("window_size must be 1 or greater"))
        new{T}(CircularBuffer{T}(window_size), window_size, SortedDict{T,Int}(), 0)
    end
end

operation_output_type(::Max{T}) where {T} = T

function reset!(op::Max{T}) where {T}
    empty!(op.buffer)
    empty!(op.counts)
    op.nan_count = 0
    nothing
end

@inline function (op::Max{T})(_, value::T) where {T<:Number}
    if isfull(op.buffer)
        dropped = popfirst!(op.buffer)
        if isnan(dropped)
            op.nan_count -= 1
        else
            cnt = op.counts[dropped] - 1
            if cnt == 0
                delete!(op.counts, dropped)
            else
                op.counts[dropped] = cnt
            end
        end
    end

    push!(op.buffer, value)
    if isnan(value)
        op.nan_count += 1
    else
        op.counts[value] = get(op.counts, value, 0) + 1
    end
    nothing
end

@inline function is_valid(op::Max{T}) where {T}
    !isempty(op.buffer)
end

@inline function get_state(op::Max{T})::T where {T}
    op.nan_count > 0 && return convert(T, NaN)
    @inbounds last(op.counts)[1]
end

export Max
