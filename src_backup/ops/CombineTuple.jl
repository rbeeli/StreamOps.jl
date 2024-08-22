"""
Combines multiple streams into a single stream by emitting
a tuple of the latest values on every update of any of the input streams.

`slot_fn` returns the index of the slot the given value is to be stored in.
"""
struct CombineTuple{N,T,K<:Function,V<:Function}
    slot_fn::K
    value_fn::V
    state::Vector{T}

    function CombineTuple{N,T}(
        ;
        slot_fn::K,
        value_fn::V=x -> x,
        init_value
    ) where {N,T,K<:Function,V<:Function}
        @assert length(init_value) == N "init_value must have length $N, but got $(length(init_value))"
        new{N,T,K,V}(
            slot_fn,
            value_fn,
            collect(init_value) # state
        )
    end
end

@inline function (op::CombineTuple{N,T,K,V})(value) where {N,T,K,V}
    # get key for index lookup in slot map
    slot_ix = op.slot_fn(value)

    # update slot with new value
    op.state[slot_ix] = op.value_fn(value)

    NTuple{N,T}(op.state)
end
