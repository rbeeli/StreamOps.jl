using Dates

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
