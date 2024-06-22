"""
Samples data based on a user-defined sampling function.
Note that the sampling function must return the downsampled value, not the original value.
A value is emitted if the downsampled value is different from the previous downsampled value.
"""
mutable struct Sample{Key,FD<:Function}
    const key_fn::FD
    last_key::Key # last sampled key value

    Sample(
        ;
        key_fn::FD,
        initial_key::Key
    ) where {Key,FD<:Function} =
        new{Key,FD}(
            key_fn,
            initial_key
        )
end

@inline (op::Sample)(value) = begin
    current_key = op.key_fn(value)

    # sample if key is different from last key
    if current_key != op.last_key
        op.last_key = current_key
        return value
    end

    nothing
end
