using DataStructures


"""
Rolling arithmetic standard deviation with fixed window size.

https://web.archive.org/web/20181222175223/http://people.ds.cam.ac.uk/fanf2/hermes/doc/antiforgery/stats.pdf
https://jonisalonen.com/2013/deriving-welfords-method-for-computing-variance/
"""
mutable struct Std{In<:Number,Out<:Number}
    const buffer::CircularBuffer{In}
    const window_size::Int
    const corrected::Bool
    M1::Out
    M2::Out

    Std{In,Out}(
        window_size::Int
        ;
        corrected=true
    ) where {In<:Number,Out<:Number} =
        new{In,Out}(
            CircularBuffer{In}(window_size),
            window_size,
            corrected,
            zero(Out), # M1
            zero(Out) # M2
        )
end

@inline (state::Std{In})(value::In) where {In<:Number} = begin
    if isfull(state.buffer)
        dropped = popfirst!(state.buffer)
        n1 = length(state.buffer)
        delta = dropped - state.M1
        delta_n = delta / n1
        state.M1 -= delta_n
        state.M2 -= delta * (dropped - state.M1)
    else
        n1 = length(state.buffer)
    end

    n = n1 + 1
    push!(state.buffer, value)

    # update states
    delta = value - state.M1
    delta_n = delta / n
    term1 = delta * delta_n * n1
    state.M1 += delta_n
    state.M2 += term1

    # calculate variance
    var = state.M2 / (state.corrected ? (n - 1) : n)

    # calculate standard deviation
    sqrt(var)
end
