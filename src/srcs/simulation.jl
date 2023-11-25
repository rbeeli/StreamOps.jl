using Dates


function simulate_chronological_stream(::Type{D}, sources) where {D <: Dates.AbstractDateTime}
    state_fn = x -> begin
        state = next!(x)
        isnothing(state) && return nothing
        state.date
    end

    # initial state of sources
    states::Vector{Union{Nothing,D}} = map(state_fn, collect(sources))

    min_items = Tuple{Int,D}[]

    while true
        # find latest source event(s)
        min_date = nothing
        @inbounds for tpl in enumerate(states)
            date = tpl[2]
            isnothing(date) && continue
            if isnothing(min_date)
                min_date = date
                push!(min_items, tpl)
            elseif date < min_date
                min_date = date
                empty!(min_items)
                push!(min_items, tpl)
            elseif date == min_date
                push!(min_items, tpl)
            end
        end

        # check if any events left
        length(min_items) == 0 && return

        # update to latest source event(s)
        @inbounds for (i, _) in min_items
            states[i] = state_fn(sources[i])
        end

        empty!(min_items)
    end
end
