"""
Calculates fractional change to previous value, also known as percent change.

Formula
=======

`` y = x\\_t / x\\_{t-1} - 1 ``
"""
mutable struct FracChange{In}
    first_output::Union{Nothing,In}
    prev_value::In

    function FracChange(
        ;
        first_output::Union{In,Nothing}=nothing,
        init_prev::Union{In,Nothing}=nothing,
    ) where {In}
        if first_output === nothing && init_prev === nothing
            throw(ArgumentError("Either `first_output` or `init_prev` must be set."))
        end
        if first_output !== nothing && init_prev !== nothing
            throw(ArgumentError("Only one of `first_output` or `init_prev` can be set."))
        end
        if first_output !== nothing
            new{In}(first_output, zero(In))
        else
            new{In}(nothing, init_prev)
        end
    end
end

# for floating-point numbers
@inline (op::FracChange{In})(value) where {In} = begin #  where {In<:AbstractFloat}
    if op.first_output !== nothing
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
# @inline (op::FracChange{In})(value) where {In} = begin
#     if op.prev_value == zero(In)
#         pct_change = zero(In) # handle division by zero
#     else
#         pct_change = (value - op.prev_value) / op.prev_value
#     end
#     op.prev_value = value
#     pct_change
# end
