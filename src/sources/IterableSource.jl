@kwdef mutable struct IterableSource{I,D,DS<:Function} <: StreamSource
    const id::I
    const data::D
    const date_selector::DS
    position::Int = 1
end


function next!(source::IterableSource{I,D,DS}) where {I,D,DS}
    pos = source.position
    pos > length(source.data) && return nothing # end of data
    source.position += 1
    value = source.data[pos]
    date = source.date_selector(value)
    StreamEvent{IterableSource{I,D,DS},typeof(date),typeof(value)}(source, date, value)
end


# function next_event_date(source::IterableSource)::Union{DateTime, Nothing}
#     source.position <= length(source.data) || return nothing # end of data
#     value = source.data[source.position]
#     DateTime(value[1])
# end
