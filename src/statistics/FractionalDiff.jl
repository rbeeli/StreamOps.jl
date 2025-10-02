using DataStructures

"""
Calculates the fractionally differenced values with a real-valued order `d`.

To limit the lookback window size, a positive cut-off weight `weight_threshold` is used,
where weights below this threshold are discarded.
"""
mutable struct FractionalDiff{In<:Number,Out<:Number} <: StreamOperation
    const init_value::Out
    const buffer::CircularBuffer{In}
    const weights::Vector{Out}
    const order::Out
    const weight_threshold::Out
    current_value::Out

    function FractionalDiff{In,Out}(
        order; init_value=zero(Out), weight_threshold=1e-4
    ) where {In<:Number,Out<:Number}
        @assert 0 <= order <= 1 "Order must be between 0 and 1 inclusive"
        weights = fractional_diff_weights(Out, order, weight_threshold)
        new{In,Out}(
            init_value,
            CircularBuffer{In}(length(weights)),
            weights,
            order,
            weight_threshold,
            Out(init_value), # current_value
        )
    end
end

function reset!(op::FractionalDiff{In,Out}) where {In,Out}
    empty!(op.buffer)
    op.current_value = op.init_value
    nothing
end

@inline function (op::FractionalDiff{In,Out})(executor, value::In) where {In<:Number,Out<:Number}
    DataStructures.push!(op.buffer, value)

    if isfull(op.buffer)
        op.current_value = sum(op.weights .* op.buffer)
    end

    nothing
end

@inline function is_valid(op::FractionalDiff{In,Out}) where {In,Out}
    isfull(op.buffer)
end

@inline function get_state(op::FractionalDiff{In,Out})::Out where {In,Out}
    op.current_value
end

operation_output_type(::FractionalDiff{In,Out}) where {In,Out} = Out

function fractional_diff_weights(::Type{T}, order, weight_threshold=1e-4) where {T}
    memory_weights = [1.0]
    k = 1
    while true
        weight = -memory_weights[end] * (order - k + 1) / k
        abs(weight) > weight_threshold || break
        push!(memory_weights, weight)
        k += 1
    end
    T.(reverse(memory_weights))
end

export FractionalDiff, fractional_diff_weights
