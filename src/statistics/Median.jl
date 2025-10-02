using DataStructures: DataStructures, MutableBinaryHeap, CircularBuffer, update!, top_with_handle

# Custom Orderings for DataStructures.MutableBinaryHeap
struct TupleForward <: Base.Ordering end
Base.lt(o::TupleForward, a, b) = a[1] < b[1]

struct TupleReverse <: Base.Ordering end
Base.lt(o::TupleReverse, a, b) = a[1] > b[1]

@enum ValueLocation::Int8 lo hi nan

"""
Efficient implementation of an online median statistic.

Runtime complexity per update: O(log n)
Space complexity: O(n)

References
----------
W. Hardle, W. Steiger 1995: Optimal Median Smoothing.
Published in:
	*Journal of the Royal Statistical Society, Series C (Applied Statistics), Vol. 44, No. 2 (1995), pp. 258-264.*
	[https://doi.org/10.2307/2986349](https://doi.org/10.2307/2986349)
"""
mutable struct Median{In<:Number,Out<:Number,full_only} <: StreamOperation
    const full_only::Bool
    const low_heap::MutableBinaryHeap{Tuple{Out,Int},TupleReverse}
    const high_heap::MutableBinaryHeap{Tuple{Out,Int},TupleForward}
    const heap_pos::CircularBuffer{Tuple{ValueLocation,Int}}
    heap_pos_offset::Int
    nans::Int

    function Median{In,Out}(window_size::Int; full_only::Bool=false) where {In<:Number,Out<:Number}
        window_size >= 1 || throw(ArgumentError("window_size must be 1 or bigger"))

        high_heap = MutableBinaryHeap{Tuple{Out,Int},TupleForward}()
        high_heap_max_size = window_size ÷ 2
        sizehint!(high_heap, high_heap_max_size)

        low_heap = MutableBinaryHeap{Tuple{Out,Int},TupleReverse}()
        sizehint!(low_heap, window_size - high_heap_max_size)

        heap_positions = CircularBuffer{Tuple{ValueLocation,Int}}(Int(window_size))

        new{In,Out,full_only}(full_only, low_heap, high_heap, heap_positions, 0, 0)
    end
end

function reset!(op::Median{In,Out,full_only}) where {In,Out,full_only}
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

@inline Base.length(med::Median) = length(med.heap_pos)

@inline DataStructures.isfull(med::Median) = DataStructures.isfull(med.heap_pos)

function _grow!(med::Median, val)
    if isnan(val)
        med.nans += 1
        push!(med.heap_pos, (nan, 0))
        return med
    end

    if length(med.low_heap) == 0
        pushed_handle = push!(med.low_heap, (val, 0))
        push!(med.heap_pos, (lo, pushed_handle))
        med.low_heap[pushed_handle] = (val, length(med.heap_pos) + med.heap_pos_offset)
        return med
    end

    if length(med.low_heap) == length(med.high_heap)
        middle_high = first(med.high_heap)
        if val <= middle_high[1]
            pushed_handle = push!(med.low_heap, (val, 0))
            push!(med.heap_pos, (lo, pushed_handle))
            med.low_heap[pushed_handle] = (val, length(med.heap_pos) + med.heap_pos_offset)
        else
            push!(med.heap_pos, med.heap_pos[middle_high[2] - med.heap_pos_offset])
            update!(
                med.high_heap,
                med.heap_pos[middle_high[2] - med.heap_pos_offset][2],
                (val, length(med.heap_pos) + med.heap_pos_offset),
            )
            pushed_handle = push!(med.low_heap, middle_high)
            med.heap_pos[middle_high[2] - med.heap_pos_offset] = (lo, pushed_handle)
        end
    else
        current_median = first(med.low_heap)
        if val >= current_median[1]
            pushed_handle = push!(med.high_heap, (val, 0))
            push!(med.heap_pos, (hi, pushed_handle))
            med.high_heap[pushed_handle] = (val, length(med.heap_pos) + med.heap_pos_offset)
        else
            push!(med.heap_pos, med.heap_pos[current_median[2] - med.heap_pos_offset])
            update!(
                med.low_heap,
                med.heap_pos[current_median[2] - med.heap_pos_offset][2],
                (val, length(med.heap_pos) + med.heap_pos_offset),
            )
            pushed_handle = push!(med.high_heap, current_median)
            med.heap_pos[current_median[2] - med.heap_pos_offset] = (hi, pushed_handle)
        end
    end

    med
end

function _shrink!(med::Median)
    to_remove = popfirst!(med.heap_pos)
    med.heap_pos_offset += 1

    if to_remove[1] == nan
        med.nans -= 1
        return med
    end

    if length(med.low_heap) == length(med.high_heap)
        if to_remove[1] == lo
            medium_high = pop!(med.high_heap)
            update!(med.low_heap, to_remove[2], medium_high)
            med.heap_pos[medium_high[2] - med.heap_pos_offset] = to_remove
        else
            delete!(med.high_heap, to_remove[2])
        end
    else
        if to_remove[1] == lo
            delete!(med.low_heap, to_remove[2])
        else
            current_median = pop!(med.low_heap)
            update!(med.high_heap, to_remove[2], current_median)
            med.heap_pos[current_median[2] - med.heap_pos_offset] = to_remove
        end
    end

    med
end

function _roll!(med::Median, val)
    to_replace = med.heap_pos[1]

    if to_replace[1] == nan || isnan(val)
        _shrink!(med)
        _grow!(med, val)
        return med
    end

    new_heap_element = (val, length(med) + med.heap_pos_offset + 1)

    if isempty(med.high_heap)
        update!(med.low_heap, to_replace[2], new_heap_element)
        _circular_push!(med.heap_pos, to_replace)
        med.heap_pos_offset += 1
        return med
    end

    if val < first(med.low_heap)[1]
        if to_replace[1] == lo
            update!(med.low_heap, to_replace[2], new_heap_element)
            _circular_push!(med.heap_pos, to_replace)
            med.heap_pos_offset += 1
        elseif to_replace[1] == hi
            low_top, low_top_ind = top_with_handle(med.low_heap)
            update!(med.high_heap, to_replace[2], low_top)
            med.heap_pos[low_top[2] - med.heap_pos_offset] = (hi, to_replace[2])
            update!(med.low_heap, low_top_ind, new_heap_element)
            _circular_push!(med.heap_pos, (lo, low_top_ind))
            med.heap_pos_offset += 1
        end
    elseif val > first(med.high_heap)[1]
        if to_replace[1] == lo
            high_top, high_top_ind = top_with_handle(med.high_heap)
            update!(med.low_heap, to_replace[2], high_top)
            med.heap_pos[high_top[2] - med.heap_pos_offset] = (lo, to_replace[2])
            update!(med.high_heap, high_top_ind, new_heap_element)
            _circular_push!(med.heap_pos, (hi, high_top_ind))
            med.heap_pos_offset += 1
        elseif to_replace[1] == hi
            update!(med.high_heap, to_replace[2], new_heap_element)
            _circular_push!(med.heap_pos, to_replace)
            med.heap_pos_offset += 1
        end
    else
        if to_replace[1] == lo
            update!(med.low_heap, to_replace[2], new_heap_element)
            _circular_push!(med.heap_pos, to_replace)
            med.heap_pos_offset += 1
        elseif to_replace[1] == hi
            update!(med.high_heap, to_replace[2], new_heap_element)
            _circular_push!(med.heap_pos, to_replace)
            med.heap_pos_offset += 1
        end
    end

    med
end

function _circular_push!(c, e)
    popfirst!(c)
    push!(c, e)
end

@inline function (op::Median{In})(executor, value::In) where {In<:Number}
    if isfull(op)
        _roll!(op, value)
    else
        _grow!(op, value)
    end
    nothing
end

@inline function is_valid(op::Median{In,Out,false}) where {In,Out}
    length(op) > 0
end

@inline function is_valid(op::Median{In,Out,true}) where {In,Out}
    isfull(op)
end

@inline function get_state(op::Median{In,Out})::Out where {In,Out}
    if op.nans > 0 || isempty(op.low_heap)
        return NaN
    end

    if length(op.low_heap) == length(op.high_heap)
        return first(op.low_heap)[1] / 2 + first(op.high_heap)[1] / 2
    else
        return first(op.low_heap)[1]
    end
end

operation_output_type(::Median{In,Out,full_only}) where {In,Out,full_only} = Out

export Median, TupleForward, TupleReverse, ValueLocation
