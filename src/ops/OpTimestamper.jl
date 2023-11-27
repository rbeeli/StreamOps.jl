using Dates


mutable struct OpTimestamper{D<:Dates.AbstractDateTime,V,F<:Function,Next<:Op} <: Op
    const next::Next
    const date_fn::F
    current_date::D
    current_value::V

    OpTimestamper{D,V}(
        ;
        date_fn::F,
        current_date::D=typemin(D),
        current_value::Union{Nothing,V}=nothing,
        next::Next=OpNone()
    ) where {D<:Dates.AbstractDateTime,V,F<:Function,Next<:Op} =
        new{D,Union{Nothing,V},F,Next}(
            next,
            date_fn,
            current_date,
            current_value
        )
end


@inline (op::OpTimestamper)(value) = begin
    op.current_value = value
    date = op.date_fn(value)
    op.current_date = isnothing(date) ? typemax(D) : date
    nothing
end


@inline function flush!(op::OpTimestamper{D}) where {D<:Dates.AbstractDateTime}
    op.next(op.current_value)
    op.current_date = typemax(D)
    op.current_value = nothing
    nothing
end


# @inline function Base.isless(x::OpTimestamper{D}, y::OpTimestamper{D}) where {D<:Dates.AbstractDateTime}
#     x.current_date < y.current_date
# end
