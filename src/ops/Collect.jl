"""
Collects all passed values to this operation in an array
called `out`. The array can be passed in from outside
in the constructor.
"""
struct Collect{E}
    out::Vector{E}

    Collect{E}(
        out::Vector{E}=E[]
    ) where {E} = new{E}(out)

    Collect(
        out::Vector{E}
    ) where {E} = new{E}(out)
end

@inline (state::Collect)(value) = begin
    push!(state.out, value)
    state.out
end
