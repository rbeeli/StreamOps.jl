"""
Prints the value. The default print function is Julia's `println`.
"""
struct Print{F<:Function}
    print_fn::F

    Print(
        ;
        print_fn::F=println
    ) where {F<:Function} = new{F}(print_fn)
end

@inline (state::Print)(value) = begin
    state.print_fn(value)
    value
end
