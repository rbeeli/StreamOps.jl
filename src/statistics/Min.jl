using DataStructures: CircularBuffer, SortedDict

"""
Maintains the rolling minimum over a fixed-size window.
The implementation updates in ``O(\\log n)`` time and uses ``O(n)`` space.

NaN values are tracked separately to avoid ordering issues; if any NaN values
are present in the current window, the reported minimum is NaN.
"""
mutable struct Min{In<:Number,Out<:Number,full_only} <: StreamOperation
    const full_only::Bool
    const buffer::CircularBuffer{In}
    const window_size::Int
    const counts::SortedDict{Out,Int}
    nan_count::Int

    function Min{In,Out}(window_size::Int; full_only::Bool=false) where {In<:Number,Out<:Number}
        window_size >= 1 || throw(ArgumentError("window_size must be 1 or greater"))
        new{In,Out,full_only}(
            full_only,
            CircularBuffer{In}(window_size),
            window_size,
            SortedDict{Out,Int}(),
            0,
        )
    end
end

operation_output_type(::Min{In,Out,full_only}) where {In,Out,full_only} = Out

function reset!(op::Min{In,Out,full_only}) where {In,Out,full_only}
    empty!(op.buffer)
    empty!(op.counts)
    op.nan_count = 0
    nothing
end

@inline function (op::Min{In,Out,full_only})(executor, value::In) where {In<:Number,Out<:Number,full_only}
    if isfull(op.buffer)
        dropped = popfirst!(op.buffer)
        if isnan(dropped)
            op.nan_count -= 1
        else
            key = convert(Out, dropped)
            cnt = op.counts[key] - 1
            if cnt == 0
                delete!(op.counts, key)
            else
                op.counts[key] = cnt
            end
        end
    end

    push!(op.buffer, value)
    if isnan(value)
        op.nan_count += 1
    else
        key = convert(Out, value)
        op.counts[key] = get(op.counts, key, 0) + 1
    end
    nothing
end

@inline function is_valid(op::Min{In,Out,false}) where {In,Out}
    !isempty(op.buffer)
end

@inline function is_valid(op::Min{In,Out,true}) where {In,Out}
    isfull(op.buffer)
end

@inline function get_state(op::Min{In,Out})::Out where {In,Out}
    if op.nan_count > 0
        return convert(Out, NaN)
    end
    first(op.counts)[1]
end

export Min
