"""
Combines multiple streams into a single stream by emitting
an array of the latest values from each stream.
The latest state is kept inside a vector, which is updated
on each event and passed downstream as reference.

`slot_fn` returns the index of the slot in the vector of
a given value.

Note: Do not modify that vector in downstream operations.
"""
struct OpCombineLatest{T,K<:Function,Next<:Op} <: Op
    next::Next
    slot_fn::K
    latest::Vector{Union{Nothing,T}}

    OpCombineLatest{T}(
        ;
        n_slots::Int,
        slot_fn::K,
        next::Next=OpNone()
    ) where {T,K<:Function,Next<:Op} =
        new{T,K,Next}(
            next,
            slot_fn,
            Vector{Union{Nothing,T}}(nothing, n_slots)
        )
end

@inline (op::OpCombineLatest)(value) = begin
    # get key for index lookup in slot map
    slot_ix = op.slot_fn(value)

    # update slot with latest value
    op.latest[slot_ix] = value

    op.next(op.latest)
end
