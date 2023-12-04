using Dates
using DataStructures


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

    # function simulate_chronological_stream(
    #     sources::Vector{TimestampedSource{D}}
    # ) where {D<:Dates.AbstractDateTime}

    #     sources_heap = BinaryMinHeap{TimestampedSource{D}}()

    #     for source in sources
    #         # next!(source)
    #         push!(sources_heap, source)
    #     end

    #     while length(sources_heap) > 0
    #         # get oldest source event
    #         source = pop!(sources_heap)

    #         # process event
    #         next!(source)

    #         # push new event to heap
    #         if source.current_date != typemax(D)
    #             push!(sources_heap, source)
    #         end
    #     end

    # # initialize latest dates
    # for source in sources
    #     next!(source)
    # end

    # latest_sources = TimestampedSource{D}[]

    # while true
    #     # find latest source event(s)
    #     min_date = typemin(D)
    #     @inbounds for time_source in sources
    #         date = time_source.current_date
    #         date == typemax(D) && continue
    #         if min_date == typemin(D)
    #             min_date = date
    #             push!(latest_sources, time_source)
    #         elseif date < min_date
    #             min_date = date
    #             empty!(latest_sources)
    #             push!(latest_sources, time_source)
    #         elseif date == min_date
    #             push!(latest_sources, time_source)
    #         end
    #     end

    #     # check if any events left
    #     length(latest_sources) == 0 && break

    #     # update to latest source event(s)
    #     for source in latest_sources
    #         next!(source)
    #     end

    #     # clear latest sources
    #     empty!(latest_sources)
    # end
end


@inline Base.isless(
    x::Tuple{Int64,D},
    y::Tuple{Int64,D}
) where {D<:Dates.AbstractDateTime} = x[2] < y[2]
