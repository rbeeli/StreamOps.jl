using Dates


mutable struct TimestampedSource{D<:Dates.AbstractDateTime,F<:Function,S<:StreamSource}
    const source::S
    const date_fn::F
    current_date::D

    TimestampedSource(
        ::Type{D}
        ;
        source::S,
        date_fn::F,
        current_date::D=typemin(D)
    ) where {D<:Dates.AbstractDateTime,S<:StreamSource,F<:Function} =
        new{D,F,S}(
            source,
            date_fn,
            current_date
        )
end


function next!(time_source::TimestampedSource{D}) where {D<:Dates.AbstractDateTime}
    state = next!(time_source.source)
    if isnothing(state)
        time_source.current_date = typemax(D)
    else
        time_source.current_date = time_source.date_fn(state)
    end
end
