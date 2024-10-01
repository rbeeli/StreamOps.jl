using DataStructures
using LinearAlgebra

"""
Calculates the moving Savitzky-Golay filter with fixed window size.

The Savitzky-Golay filter fits a polynomial of order `order` to the data in the window
and uses the polynomial to predict the smoothed value.
"""
mutable struct SavitzkyGolay{In<:Number,Out<:Number} <: StreamOperation
    const buffer::CircularBuffer{In}
    const window_size::Int
    const order::Int
    const h_table::Vector{Vector{Float64}}
    filtered::Out

    function SavitzkyGolay{In,Out}(
        window_size::Int,
        order::Int
    ) where {In<:Number,Out<:Number}
        @assert window_size > 0 "Window size must be greater than 0"
        @assert order >= 1 "Order must be greater than or equal to 1"
        h_table = _precompute_h(window_size, order)
        new{In,Out}(
            CircularBuffer{In}(window_size),
            window_size,
            order,
            h_table,
            zero(Out), # filtered
        )
    end
end

@inline function (op::SavitzkyGolay{In})(executor, value::In) where {In<:Number}
    push!(op.buffer, value)
    h = @inbounds op.h_table[length(op.buffer)]
    op.filtered = dot(h, op.buffer)
    nothing
end

@inline function is_valid(op::SavitzkyGolay{In,Out}) where {In,Out}
    !isempty(op.buffer)
end

@inline function get_state(op::SavitzkyGolay{In,Out})::Out where {In,Out}
    op.filtered
end

function _precompute_h(window_size, order)
    h_table = Vector{Vector{Float64}}()
    for n = 1:window_size
        m = min(order, n - 1)
        s = [-(n - 1) + k for k in 0:(n-1)]  # s_k values
        A = zeros(n, m + 1)

        for k = 1:n
            @inbounds for j = 1:(m+1)
                A[k, j] = s[k]^(j - 1)
            end
        end

        c = zeros(m + 1)
        c[1] = 1 # for smoothing (0th derivative)
        ATA = transpose(A) * A
        ATAc = ATA \ c
        push!(h_table, A * ATAc)
    end
    h_table
end
