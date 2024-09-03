"""
A function operation that applies an arbitrary function to the input stream
and stores the result as the last value.
"""
mutable struct Func{T,TFunc} <: StreamOperation
    const func::TFunc
    last_value::T

    function Func(func::TFunc, init::T) where {T,TFunc}
        new{T,TFunc}(func, init)
    end

    function Func{T}(func::TFunc, init::T) where {T,TFunc}
        new{T,TFunc}(func, init)
    end

    # function Func(func::TFunc) where {TFunc}
    #     new{Nothing,TFunc}(func, nothing)
    # end
end

@inline has_output(op::Func{Nothing}) = false
@inline has_output(op::Func{T}) where {T} = true

# no functor call overload needed, func is directly called, see StreamGraph.jl: _gen_execute_call!

# @inline function (op::Func{Nothing,TFunc})(args...; kwargs...) where {TFunc}
#     op.func(args...; kwargs...)
#     nothing
# end

# @inline function (op::Func{T,TFunc})(args...; kwargs...) where {T,TFunc}
#     op.last_value = op.func(args...; kwargs...)
#     nothing
# end

@inline is_valid(op::Func{Nothing}) = true
@inline is_valid(op::Func{T}) where {T} = !isnothing(op.last_value)

@inline get_state(op::Func{T}) where {T} = op.last_value
