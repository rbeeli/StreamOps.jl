"""
Returns the previous value of the input, equals a lag 1 operator.
"""
mutable struct Prev{In}
    value::In

    Prev{In}(
        ;
        init_value=one(In) # zero for default value does not work on strings, use one instead
    ) where {In<:AbstractString} = new{In}(init_value)

    Prev{In}(
        ;
        init_value=zero(In)
    ) where {In} = new{In}(init_value)
end

@inline (op::Prev)(value) = begin
    tmp = op.value
    op.value = value
    tmp
end
