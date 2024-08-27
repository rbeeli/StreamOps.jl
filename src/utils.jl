using Dates

"""
Rounds a Date/Time to the nearest period relative to an optional origin.

# Examples

```jldoctest
julia> using Dates
julia> round_origin(DateTime(2019, 1, 1, 12, 30, 0), Hour(1), RoundUp)
"2019-01-01T13:00:00"
julia> origin = DateTime(2020, 1, 1, 12, 30, 0);
julia> round_origin(DateTime(2019, 1, 1, 12, 30, 0), Hour(1), RoundUp, origin=origin)
"2019-01-01T12:30:00"
```
"""
@inline function round_origin(
    value::V,
    period::P,
    mode::Base.RoundingMode
    ;
    origin=nothing
) where {V<:Union{Dates.AbstractDateTime,Dates.AbstractTime},P<:Dates.Period}
    isnothing(origin) && return round(value, period, mode)
    origin + round(value - origin, period, mode)
end

"""
Rounds a numeric value to the nearest bucket relative to an optional origin.

# Examples

```jldoctest
julia> round_origin(4.5, 1.0, RoundUp)
5.0
julia> origin = 0.5;
julia> round_origin(1.0, 1.0, RoundDown, origin=origin)
0.5
```
"""
@inline function round_origin(
    value::V,
    bucket_width::P,
    mode::Base.RoundingMode
    ;
    origin=nothing
) where {V<:Real,P<:Real}
    isnothing(origin) && return round(value / bucket_width, mode) * bucket_width
    origin + round((value - origin) / bucket_width, mode) * bucket_width
end

# Function to recursively remove line number nodes
function _remove_line_nodes!(ex)
    ex isa Expr || return ex
    Base.remove_linenums!(ex)
    foreach(_remove_line_nodes!, ex.args)
    ex
end

# Function to print an expression without line number nodes
_print_expression(expr) = println(_remove_line_nodes!(deepcopy(expr)))
