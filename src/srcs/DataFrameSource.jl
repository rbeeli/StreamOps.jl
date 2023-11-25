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
    row = @inbounds source.as_named_tuple ? copy(source.data[pos, :]) : @view source.data[pos, :]
    date = source.date_fn(row)
    evt = StreamEvent(source.id, date, row)
    source.next(evt)
    evt
end
