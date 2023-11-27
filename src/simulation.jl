using Dates
using DataStructures


function simulate_chronological_stream(
    ::Type{D},
    sources # ::Vector{StreamSource}
) where {D<:Dates.AbstractDateTime}

    sources_heap = BinaryMinHeap{Tuple{StreamSource,OpTimestamper{D}}}()

    for source in sources
        next!(source) # initial source event
        push!(sources_heap, (source, source.next))
    end

    while length(sources_heap) > 0
        # get oldest source event
        source, op_timestamper = pop!(sources_heap)

        # flush event downstream
        flush!(op_timestamper)

        # fetch next event
        next!(source)

        # push new event to heap
        if op_timestamper.current_date != typemax(D)
            push!(sources_heap, (source, op_timestamper))
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
    x::Tuple{StreamSource,OpTimestamper{D}},
    y::Tuple{StreamSource,OpTimestamper{D}}
) where {D<:Dates.AbstractDateTime} = x[2].current_date < y[2].current_date
