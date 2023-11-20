using Dates


"""
Aggregates data over regular periods using
arbitrary user-defined function for aggregation
and periodization.

Note that dates exactly matching the current period-end-date are included in the aggregation
and cause immediate aggregation flush.

Dates must be unique and in ascending order, otherwise an error is thrown.
"""
mutable struct AggPeriodFn{In,DT,FD<:Function,FP<:Function,FA<:Function,Next<:Op} <: Op
    const next::Next
    const date_fn::FD
    const period_fn::FP
    const agg_fn::FA
    const buffer::Vector{In}
    current_period::DT
    last_date::DT
    initialized::Bool

    AggPeriodFn{In,DT}(
        ;
        date_fn::FD, # (value) -> date
        period_fn::FP, # (date) -> period_date
        agg_fn::FA, # (period, buffer) -> agg_value
        next::Next=OpNone()
    ) where {In,FD<:Function,FP<:Function,FA<:Function,DT,Next<:Op} =
        new{In,DT,FD,FP,FA,Next}(
            next,
            date_fn,
            period_fn,
            agg_fn,
            Vector{In}(), # buffer
            DT(0), # current_period
            DT(0), # last_date
            false, # initialized
        )
end

@inline (op::AggPeriodFn)(value) = begin
    dt = op.date_fn(value)
    dt_period = op.period_fn(dt)

    # check if very first value
    if !op.initialized
        op.current_period = dt_period
        op.initialized = true
    else
        # check for duplicate dates
        if dt == op.last_date
            throw(ArgumentError("Dates must be unique, got $(dt)."))
        # check if date is in ascending order
        elseif dt < op.last_date
            throw(ArgumentError("Dates must be in ascending order, got $(dt) with last date $(op.last_date)."))
        end

        # if last value date was exactly at end of period
        # causing an aggregation, then we need to update current period
        if op.last_date == op.current_period
            op.current_period = dt_period
        end
    end

    op.last_date = dt

    # check if date is at end of current period,
    # or already in new period.
    # aggregate and flush buffer if so
    end_of_period = dt == op.current_period
    in_next_period = dt > op.current_period
    if end_of_period || in_next_period
    
        # if value is end of period, add to this aggregation
        if end_of_period
            push!(op.buffer, value)
        end

        # call user-defined aggregate function
        agg_value = op.agg_fn(op.current_period, op.buffer)

        # clear buffer
        empty!(op.buffer)

        # if value is in next period, add to next aggregation
        if in_next_period
            # push new value to buffer
            push!(op.buffer, value)
        end

        # update to new period
        op.current_period = dt_period

        # push aggregate to next operation
        return op.next(agg_value)
    else
        # push new value to buffer
        push!(op.buffer, value)
    end
    
    nothing
end


"""
Rounds a datetime object to the nearest period relative to an optional origin date.
Default rounding mode is `RoundUp`.

# Examples

```jldoctest
julia> round_origin(DateTime(2019, 1, 1, 12, 30, 0), Dates.Hour(1))
"2019-01-01T13:00:00"
````
"""
function round_origin(
    dt::D,
    period::P
    ;
    mode::RoundingMode=RoundUp,
    origin=nothing
) where {D<:Dates.TimeType,P<:Period}
    if isnothing(origin)
        return round(dt, period, mode)
    end
    origin + round(dt - origin, period, mode)
end
