"""
Iterates over elements of an iterable and
passes each element to the next operator.
"""
mutable struct IterableSource{D} <: StreamSource
    const data::D
    position::Int64

    IterableSource(
        data::D
    ) where {D} =
        new{D}(
            data,
            0 # position
        )
end


function next!(src::IterableSource{D}) where {D}
    pos = src.position
    pos >= length(src.data) && return nothing # end of data
    src.position += 1
    value = @inbounds src.data[pos + 1]
    value
end
