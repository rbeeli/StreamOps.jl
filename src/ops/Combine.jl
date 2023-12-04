"""
Combines multiple streams into a single stream by emitting
a tuple of the latest values on every update of any of the input streams.

`slot_fn` returns the index of the slot in the vector of
a given value.
"""
struct Combine{T,K<:Function,C<:Function}
    slot_fn::K
    combine_fn::C
    latest::Vector{Union{Nothing,T}}

    Combine{T}(
        n_slots::Int;
        slot_fn::K,
        combine_fn::C=x -> Tuple(x)
    ) where {T,K<:Function,C<:Function} =
        new{T,K,C}(
            slot_fn,
            combine_fn,
            Vector{Union{Nothing,T}}(nothing, n_slots)
        )
end

@inline (state::Combine)(value) = begin
    # get key for index lookup in slot map
    slot_ix = state.slot_fn(value)

    # update slot with latest value
    state.latest[slot_ix] = value

    state.combine_fn(state.latest)
end
