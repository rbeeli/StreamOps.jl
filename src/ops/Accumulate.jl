"""
Calls for every value the accumulator function with the current
accumulated value and the new value.
The initial value is set to `init`.
"""
mutable struct Accumulate{Acc,F}
    const accumulator::F
    value::Acc

    Accumulate(
        accumulator::F
        ;
        init::Acc
    ) where {Acc,F<:Function} = new{Acc,F}(accumulator, init)
end

@inline (op::Accumulate)(value) = begin
    op.value = op.accumulator(op.value, value)
    op.value
end
