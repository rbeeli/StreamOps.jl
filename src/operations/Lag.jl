using DataStructures

mutable struct Lag{In} <: StreamOperation
    const buffer::CircularBuffer{In}
    const lag::Int
    counter::Int
    
    function Lag{In}(
        lag::Int=1
        ;
        init_value::In=zero(In)
    ) where {In}
        @assert lag >= 0 "Lag must be non-negative"
        buf = CircularBuffer{In}(lag+1)
        fill!(buf, init_value)
        new{In}(buf, lag, 0)
    end
end

@inline function (op::Lag)(executor, value)
    push!(op.buffer, value)
    op.counter += 1
    nothing
end

@inline is_valid(op::Lag) = op.counter > op.lag

@inline get_state(op::Lag) = @inbounds first(op.buffer)
