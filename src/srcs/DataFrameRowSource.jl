using DataFrames

"""
Iterates over each row of a DataFrame.
Each row is passed to the next operator as a view.
"""
mutable struct DataFrameRowSource{D} <: StreamSource
    const df::D
    position::Int64

    DataFrameRowSource(
        df::D
    ) where {D} =
        new{D}(
            df,
            0 # position
        )
end

function next!(src::DataFrameRowSource)
    pos = src.position
    pos >= size(src.df, 1) && return nothing # end of data frame
    row = @inbounds @view src.df[pos + 1, :]
    src.position += 1
    row
end

function reset!(src::DataFrameRowSource)
    src.position = 0
    nothing
end
