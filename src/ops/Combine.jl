"""
Combines multiple streams into a single stream by using a user-defined function
to combine the values of the input streams.

`slot_fn` returns the index of the slot the given value is to be stored in.
"""
struct Combine{N,T,K<:Function,V<:Function,C<:Function}
    slot_fn::K
    value_fn::V
    combine_fn::C
    state::Vector{Union{Nothing,T}}

    Combine{N,T}(
        ;
        slot_fn::K,
        value_fn::V=x -> x,
        combine_fn::C=x -> Tuple(x)
    ) where {N,T,K<:Function,V<:Function,C<:Function} =
        new{N,T,K,V,C}(
            slot_fn,
            value_fn,
            combine_fn,
            Vector{Union{Nothing,T}}(nothing, N) # state
        )
end

@inline function (op::Combine)(value)
    # get key for index lookup in slot map
    slot_ix = op.slot_fn(value)

    # update slot with new value
    op.state[slot_ix] = op.value_fn(value)

    op.combine_fn(op.state)
end
