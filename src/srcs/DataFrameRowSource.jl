using DataFrames


"""
Iterates over each row of a DataFrame.
Each row is passed to the next operator as a view.
"""
mutable struct DataFrameRowSource{D,Next<:Op} <: StreamSource
    const next::Next
    const data::D
    position::Int64

    DataFrameRowSource(;
        next::Next,
        data::D) where {D,Next} =
        new{D,Next}(
            next,
            data,
            0 # position
        )
end

function next!(source::DataFrameRowSource)
    pos = source.position
    pos >= nrow(source.data) && return nothing # end of data
    row = @inbounds @view source.data[pos + 1, :]
    source.next(row)
    source.position += 1
    row
end
