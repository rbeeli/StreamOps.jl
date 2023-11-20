"""
Combines multiple streams into a single stream by emitting
an array of the latest values from each stream.
The latest state is kept inside a vector, which is updated
on each event and passed downstream as reference.

Note: Do not modify that vector in downstream operations.
"""
struct OpCombineLatest{T,S<:Dict,K<:Function,Next<:Op} <: Op
    next::Next
    slot_map::S
    key_fn::K
    latest::Vector{Union{Nothing,T}}

    OpCombineLatest{T}(
        ;
        slot_map::S,
        key_fn::K,
        next::Next=OpNone()
    ) where {T,S<:Dict,K<:Function,Next<:Op} =
        new{T,S,K,Next}(
            next,
            slot_map,
            key_fn,
            Vector{Union{Nothing,T}}(nothing, length(slot_map))
        )
end

@inline (op::OpCombineLatest)(value) = begin
    # get ket for index lookup in slot map
    map_key = op.key_fn(value)

    # check key is in slot index
    if !haskey(op.slot_map, map_key)
        throw(ArgumentError("Key `$map_key` not in slot index. Valid keys: $(keys(op.slot_map))"))
    end

    # get slot index
    ix = op.slot_map[map_key]

    # update latest value
    op.latest[ix] = value

    op.next(op.latest)
end
