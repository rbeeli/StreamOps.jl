using Dates


"""
Aggregates data over user-defined time intervals.
"""
mutable struct AggPeriodFn{In,DT,FD<:Function,FP<:Function,FA<:Function,Next<:Op} <: Op
    const next::Next
    const date_fn::FD
    const period_fn::FP
    const agg_fn::FA
    const buffer::Vector{In}
    current_period::DT
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
            false, # initialized
        )
end

@inline (op::AggPeriodFn)(value) = begin
    dt = op.date_fn(value)
    dt_period = op.period_fn(dt)
    
    # println("dt = $dt period = $dt_period curr_period = $(op.current_period)")

    # check if very first value
    if !op.initialized
        op.current_period = dt_period
        op.initialized = true
    end

    # flush buffer if date is in new period
    if dt_period > op.current_period
        # call user-defined aggregate function
        agg_value = op.agg_fn(op.current_period, op.buffer)

        # clear buffer
        empty!(op.buffer)

        # update to new period
        op.current_period = dt_period

        # push new value to buffer
        push!(op.buffer, value)

        # push aggregate to next operation
        return op.next(agg_value)
    end

    # push new value to buffer
    push!(op.buffer, value)

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
@inline function round_origin(
    dt::D,
    period::P
    ;
    mode::RoundingMode=RoundUp,
    origin=nothing
) where {D<:Dates.TimeType,P<:Period}
    isnothing(origin) && return round(dt, period, mode)
    origin + round(dt - origin, period, mode)
end
