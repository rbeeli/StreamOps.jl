using Dates

"""
Iterates over a date range by a specified period
and passes each date to the next operator.
"""
mutable struct PeriodicSource{D<:Dates.AbstractDateTime,P<:Dates.Period} <: StreamSource
    const start_date::D
    const end_date::D
    const inclusive_end::Bool
    const period::P
    current_date::D

    PeriodicSource(
        start_date::D,
        end_date::D,
        period::P
        ;
        inclusive_end::Bool = false
    ) where {D,P} =
        new{D,P}(
            start_date,
            end_date,
            inclusive_end,
            period,
            start_date # current_date
        )
end

function next!(src::PeriodicSource)
    date = src.current_date
    if src.inclusive_end
        date > src.end_date && return nothing # end of data
    else
        date >= src.end_date && return nothing # end of data
    end
    src.current_date += src.period
    date
end

function reset!(src::PeriodicSource)
    src.current_date = src.start_date
    nothing
end
