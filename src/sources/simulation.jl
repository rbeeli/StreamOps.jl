using Dates


function simulate_chronological_stream(sources, pipeline)
    # initial state of sources
    states::Vector{Union{Nothing, StreamEvent}} = map(next!, sources)

    while true
        # choose source(s) with latest event
        min_items = Tuple{Int, StreamEvent}[]
        min_date = nothing
        for (i, state) in enumerate(states)
            isnothing(state) && continue
            date = state.date
            if isnothing(min_date)
                min_date = date
                push!(min_items, (i, state))
            elseif date < min_date
                min_date = date
                empty!(min_items)
                push!(min_items, (i, state))
            elseif date == min_date
                push!(min_items, (i, state))
            end            
        end
        
        # check if no more events left
        length(min_items) == 0 && return

        # emit latest events through pipeline
        # and update state
        for (i, item) in min_items
            pipeline(item)
            states[i] = next!(sources[i])
        end
    end
end
