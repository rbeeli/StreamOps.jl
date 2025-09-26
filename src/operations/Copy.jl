"""
Calls the `copy` function on the input value and stores the result
as the last value.

Note that `nothing` marks this operation as invalid.

# Arguments
- `init`: The initial value to use as the last value.
"""
mutable struct Copy{Out} <: StreamOperation
    const init::Out
    last_value::Out

    function Copy(init::Out) where {Out}
        new{Out}(init, init)
    end

    function Copy{Out}() where {Out}
        new{Union{Out,Nothing}}(nothing, nothing)
    end
end

function reset!(op::Copy)
    op.last_value = op.init
    nothing
end

@inline function (op::Copy{Out})(executor, value::V) where {Out,V}
    op.last_value = copy(value)
    nothing
end

@inline is_valid(op::Copy{Out}) where {Out} = !isnothing(op.last_value)

@inline get_state(op::Copy{Out}) where {Out} = op.last_value

export Copy, is_valid, get_state, reset!
