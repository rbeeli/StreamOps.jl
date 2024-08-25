using DataStructures

"""
Lag operation that lags the input stream by `lag` steps.
A lag value of 1 equals the previous value, which is the default.

The internal storage is a circular buffer with efficient O(1) push and pop operations.

# Arguments
- `lag=1`: The number of steps to lag the input stream.
"""
mutable struct Lag{In} <: StreamOperation
    const buffer::CircularBuffer{In}
    const lag::Int
    
    function Lag{In}(
        lag::Int=1
    ) where {In}
        @assert lag >= 0 "Lag must be non-negative"
        buf = CircularBuffer{In}(lag+1)
        new{In}(buf, lag)
    end
end

@inline function (op::Lag)(executor, value)
    push!(op.buffer, value)
    nothing
end

@inline is_valid(op::Lag) = isfull(op.buffer)

@inline get_state(op::Lag) = @inbounds first(op.buffer)
