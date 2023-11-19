"""
Prints the value and passes it on to the next op.
"""
struct OpPrint{Next<:Union{Nothing,Op}} <: Op
    next::Next

    OpPrint() = new{Nothing}(nothing)
    OpPrint(next::Next) where {Next<:Union{Nothing,Op}} = new{Next}(next)
end

@inline (op::OpPrint)(value) = begin
    println(value)
    if isnothing(op.next)
        return value
    else
        return op.next(value)
    end
end
