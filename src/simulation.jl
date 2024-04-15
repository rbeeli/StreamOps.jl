using Dates
using DataStructures

"""
Simulate a chronological stream of events from multiple sources.

The simulation is done in a chronological order, i.e. the oldest event is processed first,
and stops when all sources are exhausted.

The individual sources are assumed to be sorted in chronological order.

Uses a binary heap to keep track of the oldest event from each source.
"""
function simulate_chronological_stream(
    ::Type{D},
    sources, # ::Vector{StreamSource}
    pipelines
) where {D<:Dates.AbstractDateTime}
    @assert length(sources) == length(pipelines)

    sources_heap = BinaryMinHeap{Tuple{Int64,D}}()
    values = Vector{Any}(undef, length(sources))

    for (i, source) in enumerate(sources)
        value = next!(source) # initial data point
        values[i] = value
        push!(sources_heap, (i, value[1]))
    end

    while length(sources_heap) > 0
        # get oldest source event
        i, dt = pop!(sources_heap)

        # flush event downstream
        pipelines[i](values[i])

        # fetch next event
        value = next!(sources[i])

        isnothing(value) && continue
        
        dt = value[1]

        # push new event to heap
        if dt != typemax(D)
            push!(sources_heap, (i, dt))
            values[i] = value
        end
    end
end


@inline Base.isless(
    x::Tuple{Int64,D},
    y::Tuple{Int64,D}
) where {D<:Dates.AbstractDateTime} = x[2] < y[2]
