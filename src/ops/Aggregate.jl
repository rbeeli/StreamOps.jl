using Dates


"""
Aggregates data over user-defined grouping key and aggregation function.
"""
mutable struct Aggregate{In,Key,FP<:Function,FA<:Function}
    const key_fn::FP
    const agg_fn::FA
    const buffer::Vector{In}
    current_key::Key
    initialized::Bool

    Aggregate{In,Key}(
        ;
        key_fn::FP, # (value) -> grouping key
        agg_fn::FA # (key, buffer) -> aggregated value
    ) where {In,Key,FP<:Function,FA<:Function} =
        new{In,Key,FP,FA}(
            key_fn,
            agg_fn,
            Vector{In}(), # buffer
            zero(Key), # current_key
            false, # initialized
        )
end

@inline (state::Aggregate)(value) = begin
    key = state.key_fn(value)
    
    # check if very first value
    if !state.initialized
        state.current_key = key
        state.initialized = true
    end

    # flush buffer if date is in new period
    if key != state.current_key
        # call user-defined aggregate function
        agg_value = state.agg_fn(state.current_key, state.buffer)

        # clear buffer
        empty!(state.buffer)

        # update to new key
        state.current_key = key

        # push new value to buffer for next aggregation
        push!(state.buffer, value)

        # return aggregated value
        return agg_value
    end

    # push new value to buffer
    push!(state.buffer, value)

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
