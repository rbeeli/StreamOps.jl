mutable struct ForwardFill{In,F<:Function}
    const checker::F
    last_valid::In

    # zero for default value does not work on strings, use one instead
    ForwardFill{In}(
        checker::F
        ;
        init_value=one(In)
    ) where {In<:AbstractString,F<:Function} = new{In,F}(checker, init_value)

    ForwardFill{In}(
        checker::F
        ;
        init_value=zero(In)
    ) where {In,F<:Function} = new{In,F}(checker, init_value)
end

@inline (state::ForwardFill)(value) = begin
    # check for values that should be filled
    if state.checker(value)
        value = state.last_valid
    else
        # update fill_value with the latest valid value
        state.last_valid = value
    end
    value
end
