using Dates


function simulate_chronological_stream(
    sources::Vector{TimestampedSource{D}}
) where {D<:Dates.AbstractDateTime}

    # initialize latest dates
    next!.(sources)

    latest_sources = TimestampedSource{D}[]

    while true
        # find latest source event(s)
        min_date = typemin(D)
        @inbounds for time_source in sources
            date = time_source.current_date
            date == typemax(D) && continue
            if min_date == typemin(D)
                min_date = date
                push!(latest_sources, time_source)
            elseif date < min_date
                min_date = date
                empty!(latest_sources)
                push!(latest_sources, time_source)
            elseif date == min_date
                push!(latest_sources, time_source)
            end
        end

        # check if any events left
        length(latest_sources) == 0 && break

        # update to latest source event(s)
        next!.(latest_sources)

        # clear latest sources
        empty!(latest_sources)
    end
end
