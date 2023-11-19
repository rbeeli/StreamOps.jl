using DataFrames

@kwdef mutable struct DataFrameSource{I,D,DS<:Function} <: StreamSource
    const id::I
    const data::D
    const date_selector::DS
    const as_named_tuple::Bool = false
    position = 1
end


function next!(source::DataFrameSource{I,D,DS}) where {I,D,DS}
    pos = source.position
    pos > nrow(source.data) && return nothing # end of data
    source.position += 1
    row = source.as_named_tuple ? copy(source.data[pos, :]) : @view source.data[pos, :]
    date = source.date_selector(row)
    StreamEvent{DataFrameSource{I,D,DS},typeof(date),typeof(row)}(source, date, row)
end


# # contrustors
# DataFrameSource(;
#     data::D,
#     date_selector::DS,
#     as_named_tuple::Bool=false,
#     position=1) where {D<:AbstractDataFrame,DS<:Function} = DataFrameSource{D}(
#     data,
#     date_selector,
#     as_named_tuple,
#     position)


# function next_event_date(source::DataFrameSource)::Union{DateTime, Nothing}
#     source.position <= nrow(source.data) || return nothing # end of data
#     DateTime(source.data[!, source.date_column][source.position])
# end
