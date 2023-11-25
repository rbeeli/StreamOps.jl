@kwdef mutable struct IterableSource{I,D,DS<:Function,Next<:Op} <: StreamSource
    const next::Next
    const id::I
    const data::D
    const date_fn::DS
    position::Int = 1
end


function next!(source::IterableSource)
    pos = source.position
    pos > length(source.data) && return nothing # end of data
    source.position += 1
    value = @inbounds source.data[pos]
    date = source.date_fn(value)
    evt = StreamEvent(source.id, date, value)
    source.next(evt)
    evt
end
