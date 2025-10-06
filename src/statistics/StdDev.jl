using DataStructures: CircularBuffer

"""
Calculates the simple moving standard deviation with fixed window size in O(1) time.

# Arguments
- `window_size`: The number of observations to consider in the moving window.
- `corrected=true`: Use Bessel's correction to compute the unbiased sample standard deviation.

# References
https://web.archive.org/web/20181222175223/http://people.ds.cam.ac.uk/fanf2/hermes/doc/antiforgery/stats.pdf
https://jonisalonen.com/2013/deriving-welfords-method-for-computing-variance/
"""
mutable struct StdDev{In<:Number,Out<:Number,corrected} <: StreamOperation
    const buffer::CircularBuffer{In}
    const window_size::Int
    const corrected::Bool
    M1::Out
    M2::Out

    function StdDev{In,Out}(window_size::Int; corrected::Bool=true) where {In<:Number,Out<:Number}
        @assert window_size > 0 "Window size must be greater than 0"
        new{In,Out,corrected}(
            CircularBuffer{In}(window_size),
            window_size,
            corrected,
            zero(Out), # M1
            zero(Out), # M2
        )
    end
end

operation_output_type(::StdDev{In,Out,corrected}) where {In,Out,corrected} = Out

function reset!(op::StdDev{In,Out,corrected}) where {In,Out,corrected}
    empty!(op.buffer)
    op.M1 = zero(Out)
    op.M2 = zero(Out)
    nothing
end

@inline function (op::StdDev{In})(executor, value::In) where {In<:Number}
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

    # update states
    delta = value - op.M1
    delta_n = delta / n
    term1 = delta * delta_n * n1
    op.M1 += delta_n
    op.M2 += term1

    nothing
end

@inline function is_valid(op::StdDev{In,Out}) where {In,Out}
    isfull(op.buffer)
end

# biased std. deviation
@inline function get_state(op::StdDev{In,Out,false})::Out where {In,Out}
    op.window_size > 0 ? sqrt(max(zero(Out), op.M2 / op.window_size)) : zero(Out)
end

# unbiased std. deviation
@inline function get_state(op::StdDev{In,Out,true})::Out where {In,Out}
    op.window_size > 1 ? sqrt(max(zero(Out), op.M2 / (op.window_size - 1))) : zero(Out)
end

export StdDev
