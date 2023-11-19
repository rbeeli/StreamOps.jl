using DataStructures


"""
Rolling arithmetic standard deviation with fixed window size.

https://web.archive.org/web/20181222175223/http://people.ds.cam.ac.uk/fanf2/hermes/doc/antiforgery/stats.pdf
https://jonisalonen.com/2013/deriving-welfords-method-for-computing-variance/
"""
mutable struct OpStd{In<:Number,Out<:Number,Next<:Op} <: Op
    const next::Next
    const buffer::CircularBuffer{In}
    const window_size::Int
    const corrected::Bool
    M1::Out
    M2::Out

    OpStd{In,Out}(window_size::Int, next::Next; corrected=true) where {In<:Number,Out<:Number,Next<:Op} =
        new{In,Out,Next}(
            next,
            CircularBuffer{In}(window_size),
            window_size,
            corrected,
            zero(Out), # M1
            zero(Out) # M2
        )
end

@inline (op::OpStd{In})(value::In) where {In<:Number} = begin
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

    # calculate variance
    var = op.M2 / (op.corrected ? (n - 1) : n)

    # calculate standard deviation
    std = sqrt(var)

    op.next(std)
end
