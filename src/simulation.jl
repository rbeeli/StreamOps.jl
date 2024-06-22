using Dates
using DataStructures

struct SimChronoItem{D}
    i::Int
    date::D
end

"""
Simulate a chronological stream of events from multiple sources.

The simulation is done in a chronological order, i.e. the oldest event is processed first,
and stops when all sources are exhausted.

The individual sources are assumed to be sorted in chronological order.

Uses a binary heap to keep track of the oldest event from each source.

Parameters
=========
D : Type
    The type of the date of the event.

V : Type
    The type of the event. Use Union if the events are of different types.

sources : Vector{StreamSource}
    The sources of the events.

date_fns : Vector{Function}
    The functions to extract the date from the event.

pipelines : Vector{Function}
    The functions to process the event of each source.
"""
function simulate_chronological_stream(
    ::Type{D},
    ::Type{V},
    sources,
    date_fns,
    pipelines
) where {D<:Dates.AbstractDateTime,V}
    @assert length(sources) == length(pipelines)
    @assert length(sources) == length(date_fns)

    queue = BinaryMinHeap{SimChronoItem{D}}()
    events = Vector{Union{V,Nothing}}(undef, length(sources))

    # initialize heap
    for (i, source) in enumerate(sources)
        event::Union{V,Nothing} = next!(source)
        events[i] = event
        isnothing(event) && continue
        date::D = @inbounds date_fns[i](event)
        push!(queue, SimChronoItem(i, date))
    end

    while length(queue) > 0
        # get oldest source event
        item = pop!(queue)
        i = item.i
        date = item.date

        # flush event downstream
        event::Union{V,Nothing} = @inbounds events[i]
        if !isnothing(event)
            @inbounds pipelines[i](event)
        end

        # fetch next event
        next_event = next!(@inbounds sources[i])

        isnothing(next_event) && continue

        date::D = @inbounds date_fns[i](next_event)

        # push new event to heap
        if date != typemax(D)
            push!(queue, SimChronoItem(i, date))
            @inbounds events[i] = next_event
        end
    end
end

@inline Base.isless(
    x::SimChronoItem{D},
    y::SimChronoItem{D}
) where {D<:Dates.AbstractDateTime} = x.date < y.date
