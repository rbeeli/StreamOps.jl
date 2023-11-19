import Base

struct StreamEvent{S<:StreamSource,D,V}
    source::S
    date::D
    value::V
end

Base.show(io::IO, e::StreamEvent) = print(io, "$(e.source.id) $(e.date): $(e.value)")
