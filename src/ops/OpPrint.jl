"""
Prints the value and passes it on to the next op.
The default print function is Julia's `println`.
"""
struct OpPrint{F<:Function,Next<:Op} <: Op
    next::Next
    print_fn::F

    OpPrint(
        ;
        print_fn::F=println,
        next::Next=OpNone()
    ) where {F<:Function,Next<:Op} = new{F,Next}(next, print_fn)
end

@inline (op::OpPrint)(value) = begin
    op.print_fn(value)
    if isnothing(op.next)
        return value
    else
        return op.next(value)
    end
end
