"""
Calculates the cumulative sum of incoming values, starting from an initial value.

# Type Parameters
- `In`: Input number type
- `Out`: Output number type

# Arguments
- `init::Out=zero(Out)`: The initial value to start the cumulative sum from
- `init_valid::Bool=false`: Whether the initial value is considered a valid state
"""
mutable struct CumSum{In<:Number,Out<:Number} <: StreamOperation
    const init::Out
    sum::Out
    valid::Bool

    function CumSum{In,Out}(
        ;
        init::Out=zero(Out),
        init_valid::Bool=false
    ) where {In<:Number,Out<:Number}
        new{In,Out}(init, init, init_valid)
    end
end

@inline function (op::CumSum{In,Out})(executor, value::In) where {In<:Number,Out<:Number}
    op.sum += value
    op.valid = true
    nothing
end

@inline function is_valid(op::CumSum)
    op.valid
end

@inline function get_state(op::CumSum{In,Out})::Out where {In,Out}
    op.sum
end

@inline function Base.empty!(op::CumSum{In,Out}) where {In,Out}
    op.sum = op.init
    op.valid = false
    nothing
end
