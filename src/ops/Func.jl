"""
Applies arbitrary function.
"""
struct Func{F}
    fn::F
    Func(fn::F) where {F} = new{F}(fn)
end

@inline (state::Func)(value) = state.fn(value)
