using Dates


"""
Iterates over a date range by a specified period
and passes each date to the next operator.
"""
mutable struct PeriodicSource{D<:Dates.AbstractDateTime,P<:Dates.Period,Next<:Op} <: StreamSource
    const next::Next
    const start_date::D
    const end_date::D
    const inclusive_end::Bool
    const period::P
    current_date::D

    PeriodicSource(;
        next::Next,
        start_date::D,
        end_date::D,
        period::P,
        inclusive_end::Bool = false
    ) where {D,P,Next} =
        new{D,P,Next}(
            next,
            start_date,
            end_date,
            inclusive_end,
            period,
            start_date # current_date
        )
end

function next!(source::PeriodicSource)
    date = source.current_date
    if source.inclusive_end
        date > source.end_date && return nothing # end of data
    else
        date >= source.end_date && return nothing # end of data
    end
    source.next(date)
    source.current_date += source.period
    date
end
