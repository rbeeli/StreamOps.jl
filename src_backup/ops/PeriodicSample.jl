using Dates

"""
Samples data periodically at a fixed interval.
"""
mutable struct PeriodicSample{TDate,FD<:Function}
    const date_fn::FD
    const origin::TDate
    const period::Dates.Period
    last_date::TDate # last sampled date value

    PeriodicSample{TDate}(
        ;
        date_fn::FD,
        period::Dates.Period,
        initial_date::TDate=TDate(0),
        origin=TDate(0)
    ) where {TDate<:Dates.TimeType,FD<:Function} =
        new{TDate,FD}(
            date_fn,
            origin,
            period,
            initial_date
        )
end

@inline (op::PeriodicSample)(value) = begin
    current_date = round_origin(op.date_fn(value), op.period; origin=op.origin)

    # sample if date is different from last date
    if current_date != op.last_date
        op.last_date = current_date
        return value
    end

    nothing
end
