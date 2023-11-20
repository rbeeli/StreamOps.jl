using Dates


function simulate_chronological_stream(sources)
    # initial state of sources
    states::Vector{Union{Nothing,StreamEvent}} = map(next!, collect(sources))

    while true
        # find latest source event(s)
        min_items = Tuple{Int,StreamEvent}[]
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

        # check if any events left
        length(min_items) == 0 && return

        # update to latest source event(s)
        for (i, item) in min_items
            states[i] = next!(sources[i])
        end
    end
end
