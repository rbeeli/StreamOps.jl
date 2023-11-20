using DataFrames

@kwdef mutable struct DataFrameSource{I,D,DS<:Function,Next<:Op} <: StreamSource
    const next::Next
    const id::I
    const data::D
    const date_fn::DS
    const as_named_tuple::Bool = false
    position = 1
end


function next!(source::DataFrameSource)
    pos = source.position
    pos > nrow(source.data) && return nothing # end of data
    source.position += 1
    row = source.as_named_tuple ? copy(source.data[pos, :]) : @view source.data[pos, :]
    date = source.date_fn(row)
    evt = StreamEvent(source, date, row)
    source.next(evt)
    evt
end


# # contrustors
# DataFrameSource(;
#     data::D,
#     date_fn::DS,
#     as_named_tuple::Bool=false,
#     position=1) where {D<:AbstractDataFrame,DS<:Function} = DataFrameSource{D}(
#     data,
#     date_fn,
#     as_named_tuple,
#     position)


# function next_event_date(source::DataFrameSource)::Union{DateTime, Nothing}
#     source.position <= nrow(source.data) || return nothing # end of data
#     DateTime(source.data[!, source.date_column][source.position])
# end
