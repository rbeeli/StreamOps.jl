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
    source.position >= length(source.data) && return nothing # end of data
    source.position += 1
    value = @inbounds source.data[source.position]
    source.next(value)
    value
end
