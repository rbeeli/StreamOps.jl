mutable struct OpForwardFill{In,F<:Function,Next<:Op} <: Op
    const next::Next
    const checker::F
    last_valid::In

    # zero for default value does not work on strings, use one instead
    OpForwardFill{In}(
        checker::F
        ;
        init_value=one(In),
        next::Next=OpNone()
    ) where {In<:AbstractString,F<:Function,Next<:Op} = new{In,F,Next}(next, checker, init_value)

    OpForwardFill{In}(
        checker::F
        ;
        init_value=zero(In),
        next::Next=OpNone()
    ) where {In,F<:Function,Next<:Op} = new{In,F,Next}(next, checker, init_value)
end

@inline (op::OpForwardFill)(value) = begin
    # check for values that should be filled
    if op.checker(value)
        value = op.last_valid
    else
        # update fill_value with the latest valid value
        op.last_valid = value
    end
    op.next(value)
end
