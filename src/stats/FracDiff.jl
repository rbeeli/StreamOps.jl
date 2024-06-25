using DataStructures
using StatsBase

function frac_diff_weights(::Type{T}, order, weight_threshold=1e-4) where {T}
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

"""
Performs fractional differencing of real-valued order `d` on a stream of numbers.
To limit the lookback window, a positive cutoff weight `weight_threshold` is used.
"""
struct FracDiff{In<:Number,Out<:Number}
    buffer::CircularBuffer{In}
    weights::Vector{Out}
    order::Out
    init_value::Out
    weight_threshold::Out

    function FracDiff{In,Out}(
        order
        ;
        init_value=zero(Out),
        weight_threshold=1e-4
    ) where {In<:Number,Out<:Number}
        weights = frac_diff_weights(Out, order, weight_threshold)
        new{In,Out}(
            CircularBuffer{In}(length(weights)),
            weights,
            order,
            init_value,
            weight_threshold
        )
    end
end

@inline (op::FracDiff{In})(value::In) where {In<:Number} = begin
    DataStructures.push!(op.buffer, value)
    
    if length(op.buffer) < length(op.weights)
        return op.init_value
    end

    sum(op.weights .* op.buffer)
end
