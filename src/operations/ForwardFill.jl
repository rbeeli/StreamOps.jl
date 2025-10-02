"""
A forward fill operation that fills missing values with the last valid value.

The `should_fill_fn` function is used to determine if a value should be filled
with the last valid value.

# Arguments
- `should_fill_fn` A function that returns `true` if a value should be filled.
- `init=zero(T)`: The initial value to use as the last valid value.
"""
mutable struct ForwardFill{T,F<:Function} <: StreamOperation
    const should_fill_fn::F
    const init::T
    called::Bool
    last_valid::T

    # constructor for String type with default fill function
    function ForwardFill{T}(
        should_fill_fn::F=(x) -> (ismissing(x) || x == ""); init=""
    ) where {T<:String,F<:Function}
        new{T,F}(should_fill_fn, init, false, init)
    end

    # default constructor
    function ForwardFill{T}(
        should_fill_fn::F=(x) -> (ismissing(x) || isnan(x)); init=zero(T)
    ) where {T,F<:Function}
        new{T,F}(should_fill_fn, init, false, init)
    end
end

operation_output_type(::ForwardFill{T}) where {T} = T

function reset!(op::ForwardFill)
    op.called = false
    op.last_valid = op.init
    nothing
end

@inline function (op::ForwardFill{T,F})(executor, value) where {T,F}
    if !op.should_fill_fn(value)
        # don't fill, just update last_valid
        op.last_valid = value
    end

    op.called = true

    nothing
end

@inline is_valid(op::ForwardFill) = op.called

@inline get_state(op::ForwardFill{T}) where {T} = op.last_valid

export ForwardFill
