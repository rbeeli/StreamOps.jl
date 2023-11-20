using Dates


@kwdef mutable struct PeriodicSource{I,D<:Dates.AbstractDateTime,Next<:Op} <: StreamSource
    const next::Next
    const id::I
    const start_date::D
    const end_date::D
    const inclusive_end::Bool = false
    const period::Dates.Period
    current_date::D
end


function next!(source::PeriodicSource)
    date = source.current_date
    source.inclusive_end && date > source.end_date && return nothing # end of data
    !source.inclusive_end && date >= source.end_date && return nothing # end of data
    source.current_date += source.period
    value = date
    evt = StreamEvent(source, date, value)
    source.next(evt)
    evt
end


# function next_event_date(source::PeriodicSource)::Union{DateTime, Nothing}
#     inclusive_end && source.current_date <= source.end_date || return nothing # end of data
#     !inclusive_end && source.current_date < source.end_date || return nothing # end of data
#     DateTime(source.current_date)
# end