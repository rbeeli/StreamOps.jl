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
    called::Bool
    last_valid::T

    # constructor for String type with default fill function
    ForwardFill{T}(
        should_fill_fn::F=(x) -> (ismissing(x) || x == "")
        ;
        init=""
    ) where {T<:String,F<:Function} = new{T,F}(should_fill_fn, false, init)

    # default constructor
    ForwardFill{T}(
        should_fill_fn::F=(x) -> (ismissing(x) || isnan(x))
        ;
        init=zero(T)
    ) where {T,F<:Function} = new{T,F}(should_fill_fn, false, init)
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
