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

function next!(source::DataFrameRowSource)
    pos = source.position
    pos >= nrow(source.df) && return nothing # end of data frame
    row = @inbounds @view source.df[pos + 1, :]
    source.position += 1
    row
end
