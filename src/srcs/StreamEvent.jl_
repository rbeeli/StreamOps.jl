import Base

struct StreamEvent{S,D,V}
    source::S
    date::D
    value::V

    StreamEvent(source::S, date::D, value::V) where {S,D,V} = new{S,D,V}(source, date, value)
end

Base.show(io::IO, e::StreamEvent) = print(io, "StreamEvent source=$(e.source) date=$(e.date) value=$(e.value)")
