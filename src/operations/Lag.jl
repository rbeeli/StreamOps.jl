using DataStructures

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
