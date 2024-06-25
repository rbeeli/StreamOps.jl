"""
Aggregates data over user-defined grouping key and aggregation function.
"""
mutable struct Aggregate{In,Key,FP<:Function,FA<:Function}
    const key_fn::FP
    const agg_fn::FA
    const buffer::Vector{In}
    last_key::Key

    Aggregate{In}(
        ;
        key_fn::FP, # (value) -> grouping key
        agg_fn::FA, # (key, buffer) -> aggregated value,
        initial_key::Key
    ) where {In,Key,FP<:Function,FA<:Function} =
        new{In,Key,FP,FA}(
            key_fn,
            agg_fn,
            Vector{In}(), # buffer
            initial_key # last_key
        )
end

@inline (op::Aggregate)(value) = begin
    current_key = op.key_fn(value)

    # aggregate if key is different from last key
    if current_key != op.last_key
        # call user-defined aggregation function
        agg_value = op.agg_fn(op.last_key, op.buffer)

        # clear buffer
        empty!(op.buffer)

        # update to new key
        op.last_key = current_key

        # push new value to buffer for next aggregation
        push!(op.buffer, value)

        return agg_value
    end

    # push new value to buffer
    push!(op.buffer, value)

    nothing
end
