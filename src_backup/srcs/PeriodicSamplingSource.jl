using Dates

"""
Samples data periodically at a fixed interval.
Gap filling can optionally be enabled.
"""
mutable struct PeriodicSamplingSource{
    TDate<:Dates.AbstractDateTime,
    TPeriod<:Dates.Period,
    TFunc<:Function,
    TFill<:Function,
    TData,
    TPipeline,
    TIterator,
    TExecutor<:StreamExecutor
} <: StreamSource
    const executor::TExecutor
    const date_fn::TFunc
    const pipeline::TPipeline
    const origin::TDate
    const period::TPeriod
    const fill_gaps::Bool
    const fill_fn::TFill
    const data::TData
    const initial_date::TDate
    iterator::TIterator
    last_date::TDate # last sampled date value

    function PeriodicSamplingSource{TDate}(
        executor::TExecutor,
        data::TData,
        pipeline::TPipeline
        ;
        date_fn::TFunc,
        period::TPeriod,
        initial_date::TDate=TDate(0),
        fill_gaps::Bool=false,
        fill_fn::TFill=(date, value) -> nothing,
        origin=TDate(0)
    ) where {TDate,TPeriod,TFunc,TFill,TData,TPipeline,TExecutor}
        iterator = Base.iterate(data)

        obj = new{TDate,TPeriod,TFunc,TFill,TData,TPipeline,Union{Nothing,typeof(iterator)},TExecutor}(
            executor,
            date_fn,
            pipeline,
            origin,
            period,
            fill_gaps,
            fill_fn,
            data,
            initial_date,
            iterator,
            initial_date
        )
        
        # register source with executor
        register_source!(executor, obj)

        obj
    end
end

function start!(src::PeriodicSamplingSource)::Bool
    next!(src)
end

function next!(src::PeriodicSamplingSource)::Bool
    if isnothing(src.iterator)
        return false
    end

    element, state = src.iterator
    current_date = src.last_date

    while current_date == src.last_date
        # advance iterator
        src.iterator = Base.iterate(src.data, state)
        if isnothing(src.iterator)
            break
        end
        element, state = src.iterator
        current_date = round_origin(src.date_fn(element), src.period; origin=src.origin)
    end

    # sample if date is different from last date
    if current_date != src.last_date
        if src.fill_gaps && src.last_date != src.initial_date
            while src.last_date + src.period < current_date
                src.last_date += src.period
                fill_value = src.fill_fn(src.last_date, element)
                push_event!(src.executor, src, src.last_date, fill_value)
            end
        end
        src.last_date = current_date
        push_event!(src.executor, src, src.last_date, element)
    end

    !isnothing(src.iterator)
end

@inline (op::PeriodicSamplingSource)(value) = begin
    push!(op.data, value)
    next!(op)
end
