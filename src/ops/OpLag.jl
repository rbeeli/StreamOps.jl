mutable struct OpLag{In,Next<:Op} <: Op
    const next::Next
    const buffer::Vector{In}
    const lag::Int
    index::Int

    OpLag{In}(lag::Int, next::Next; init_value::In=zero(In)) where {In,Next<:Op} =
        new{In,Next}(next, fill(init_value, lag), lag, 1)
end

@inline (op::OpLag)(value) = begin
    lagged_value = op.buffer[op.index]
    op.buffer[op.index] = value
    op.index = op.index % op.lag + 1
    op.next(lagged_value)
end
