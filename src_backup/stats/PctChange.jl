"""
Calculates percentage change to previous value.

Formula
=======

`` y = x\\_t / x\\_{t-1} - 1 ``
"""
mutable struct PctChange{In<:Number}
    first_output::Union{Nothing,In}
    prev_value::In

    function PctChange(
        ;
        first_output::Union{In,Nothing}=nothing,
        init_prev::Union{In,Nothing}=nothing,
    ) where {In<:Number}
        if isnothing(first_output) && isnothing(init_prev)
            throw(ArgumentError("Either `first_output` or `init_prev` must be set."))
        end
        if !isnothing(first_output) && !isnothing(init_prev)
            throw(ArgumentError("Only one of `first_output` or `init_prev` can be set."))
        end
        if !isnothing(first_output)
            new{In}(first_output, zero(In))
        else
            new{In}(nothing, init_prev)
        end
    end
end

# for floating-point numbers
@inline (op::PctChange{In})(value) where {In} = begin #  where {In<:AbstractFloat}
    if !isnothing(op.first_output)
        op.prev_value = value
        out = op.first_output
        op.first_output = nothing
        return out
    end
    change = value / op.prev_value - one(In)
    op.prev_value = value
    change
end

# # for other numeric types, including integers
# @inline (op::PctChange{In})(value) where {In} = begin
#     if op.prev_value == zero(In)
#         pct_change = zero(In) # handle division by zero
#     else
#         pct_change = (value - op.prev_value) / op.prev_value
#     end
#     op.prev_value = value
#     pct_change
# end
