import DataStructures
using DataStructures: MutableBinaryHeap, CircularBuffer, isfull

"""
Efficient implementation of an online sliding-window quantile statistic.
Maintains two heaps to track order statistics in O(log n) per update.
"""
mutable struct Quantile{In<:Number,Out<:Number,full_only} <: StreamOperation
    const quantile::Float64
    const full_only::Bool
    const low_heap::MutableBinaryHeap{Tuple{Out,Int},TupleReverse}
    const high_heap::MutableBinaryHeap{Tuple{Out,Int},TupleForward}
    const heap_pos::CircularBuffer{Tuple{ValueLocation,Int}}
    heap_pos_offset::Int
    nans::Int

    function Quantile{In,Out}(window_size::Int, quantile::Real; full_only::Bool=false) where {In<:Number,Out<:Number}
        window_size >= 1 || throw(ArgumentError("window_size must be 1 or bigger"))
        quantile_val = Float64(quantile)
        0.0 <= quantile_val <= 1.0 || throw(ArgumentError("quantile must lie in [0, 1]"))
        isfinite(quantile_val) || throw(ArgumentError("quantile must be finite"))

        high_heap = MutableBinaryHeap{Tuple{Out,Int},TupleForward}()
        sizehint!(high_heap, window_size)

        low_heap = MutableBinaryHeap{Tuple{Out,Int},TupleReverse}()
        sizehint!(low_heap, window_size)

        heap_positions = CircularBuffer{Tuple{ValueLocation,Int}}(Int(window_size))

        new{In,Out,full_only}(quantile_val, full_only, low_heap, high_heap, heap_positions, 0, 0)
    end
end

operation_output_type(::Quantile{In,Out,full_only}) where {In,Out,full_only} = Out

function reset!(op::Quantile{In,Out,full_only}) where {In,Out,full_only}
    while !isempty(op.low_heap)
        pop!(op.low_heap)
    end
    while !isempty(op.high_heap)
        pop!(op.high_heap)
    end
    empty!(op.heap_pos)
    op.heap_pos_offset = 0
    op.nans = 0
    nothing
end

@inline Base.length(op::Quantile) = length(op.heap_pos)

@inline DataStructures.isfull(op::Quantile) = DataStructures.isfull(op.heap_pos)

@inline function _set_heap_pos!(op::Quantile, global_index::Int, loc::ValueLocation, handle::Int)
    idx = global_index - op.heap_pos_offset
    @inbounds op.heap_pos[idx] = (loc, handle)
end

@inline function _target_low_size(op::Quantile, n::Int)
    if n == 0
        return 0
    end
    h = (n - 1) * op.quantile + 1
    k = floor(Int, h)
    k < 1 && return 1
    k > n && return n
    k
end

function _rebalance!(op::Quantile)
    n = length(op.low_heap) + length(op.high_heap)
    target_low = _target_low_size(op, n)

    while length(op.low_heap) > target_low
        moved = pop!(op.low_heap)
        handle = push!(op.high_heap, moved)
        _set_heap_pos!(op, moved[2], hi, handle)
    end

    while length(op.low_heap) < target_low && !isempty(op.high_heap)
        moved = pop!(op.high_heap)
        handle = push!(op.low_heap, moved)
        _set_heap_pos!(op, moved[2], lo, handle)
    end

    op
end

function _grow!(op::Quantile, value)
    if isnan(value)
        op.nans += 1
        push!(op.heap_pos, (nan, 0))
        return op
    end

    global_index = length(op.heap_pos) + op.heap_pos_offset + 1

    if isempty(op.low_heap) || value <= first(op.low_heap)[1]
        handle = push!(op.low_heap, (value, global_index))
        push!(op.heap_pos, (lo, handle))
    else
        handle = push!(op.high_heap, (value, global_index))
        push!(op.heap_pos, (hi, handle))
    end

    _rebalance!(op)
end

function _shrink!(op::Quantile)
    to_remove = popfirst!(op.heap_pos)
    op.heap_pos_offset += 1

    if to_remove[1] == nan
        op.nans -= 1
        return op
    elseif to_remove[1] == lo
        delete!(op.low_heap, to_remove[2])
    else
        delete!(op.high_heap, to_remove[2])
    end

    _rebalance!(op)
end

function _roll!(op::Quantile, value)
    _shrink!(op)
    _grow!(op, value)
end

@inline function (op::Quantile{In})(executor, value::In) where {In<:Number}
    if isfull(op)
        _roll!(op, value)
    else
        _grow!(op, value)
    end
    nothing
end

@inline function is_valid(op::Quantile{In,Out,false}) where {In,Out}
    length(op) > 0
end

@inline function is_valid(op::Quantile{In,Out,true}) where {In,Out}
    isfull(op)
end

@inline function get_state(op::Quantile{In,Out})::Out where {In,Out}
    if op.nans > 0 || isempty(op.low_heap)
        return NaN
    end

    n = length(op.low_heap) + length(op.high_heap)
    h = (n - 1) * op.quantile + 1
    lower_index = floor(Int, h)
    alpha = h - lower_index

    lower_value = first(op.low_heap)[1]

    if alpha == 0.0 || isempty(op.high_heap)
        return lower_value
    else
        upper_value = first(op.high_heap)[1]
        return lower_value + alpha * (upper_value - lower_value)
    end
end

export Quantile

