using DataStructures

"""
    ZScore{In<:Number,Out<:Number,corrected}

Calculates the simple moving z-score with a fixed window size in O(1) time.

The z-score is computed as `(x - μ) / σ`, where `x` is the current value, `μ` is the mean,
and `σ` is the standard deviation of the values in the moving window.

# Type parameters
- `In`: Input number type
- `Out`: Output number type
- `corrected`: Boolean flag for variance correction

# Constructor
    ZScore{In,Out}(window_size::Int; corrected::Bool=true) where {In<:Number,Out<:Number}

Constructs a ZScore object with the specified window size and correction flag.

# Arguments
- `window_size::Int`: Size of the moving window (must be greater than 0)
- `corrected::Bool=true`: Whether to use corrected (unbiased) variance (default is true)
"""
mutable struct ZScore{In<:Number,Out<:Number,corrected} <: StreamOperation
    const buffer::CircularBuffer{In}
    const window_size::Int
    const corrected::Bool
    M1::Out  # Mean
    M2::Out  # Variance * (n-1)
    current::Out

    function ZScore{In,Out}(
        window_size::Int
        ;
        corrected::Bool=true
    ) where {In<:Number,Out<:Number}
        @assert window_size > 0 "Window size must be greater than 0"
        new{In,Out,corrected}(
            CircularBuffer{In}(window_size),
            window_size,
            corrected,
            zero(Out), # M1 (Mean)
            zero(Out), # M2 (Variance * (n-1))
            zero(Out)  # current
        )
    end
end

@inline function (op::ZScore{In,Out})(executor, value::In) where {In<:Number,Out<:Number}
    if isfull(op.buffer)
        dropped = popfirst!(op.buffer)
        n1 = length(op.buffer)
        delta = dropped - op.M1
        delta_n = delta / n1
        op.M1 -= delta_n
        op.M2 -= delta * (dropped - op.M1)
    else
        n1 = length(op.buffer)
    end

    n = n1 + 1
    push!(op.buffer, value)

    # Update mean and variance
    delta = value - op.M1
    delta_n = delta / n
    term1 = delta * delta_n * n1
    op.M1 += delta_n
    op.M2 += term1

    # Calculate z-score
    if n > 1
        variance = calculate_variance(op, n)
        std_dev = sqrt(variance)
        op.current = (value - op.M1) / std_dev
    else
        op.current = Out(NaN)
    end

    nothing
end

@inline function is_valid(op::ZScore{In,Out}) where {In,Out}
    isfull(op.buffer)
end

@inline function get_state(op::ZScore{In,Out})::Out where {In,Out}
    op.current
end

# Corrected (unbiased) variance calculation
@inline function calculate_variance(op::ZScore{In,Out,true}, n::Int)::Out where {In,Out}
    op.M2 / (n - 1)
end

# Uncorrected (biased) variance calculation
@inline function calculate_variance(op::ZScore{In,Out,false}, n::Int)::Out where {In,Out}
    op.M2 / n
end