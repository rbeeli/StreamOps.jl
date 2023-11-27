"""
Iterates over elements of an iterable and
passes each element to the next operator.
"""
mutable struct IterableSource{D,Next<:Op} <: StreamSource
    const next::Next
    const data::D
    position::Int64

    IterableSource(;
        next::Next,
        data::D) where {D,Next} =
        new{D,Next}(
            next,
            data,
            0 # position
        )
end

function next!(source::IterableSource)
    pos = source.position
    pos >= length(source.data) && return nothing # end of data
    value = @inbounds source.data[pos + 1]
    source.next(value)
    source.position += 1
    value
end
