"""
A function operation that applies an arbitrary function to the input stream
and stores the result as the last value.
"""
mutable struct Func{T,TFunc,TIsValid} <: StreamOperation
    const func::TFunc
    const is_valid::TIsValid
    const init::T
    last_value::T

    function Func(func::TFunc, init::T; is_valid::TIsValid=!isnothing) where {T,TFunc,TIsValid}
        new{T,TFunc,TIsValid}(func, is_valid, init, init)
    end

    function Func{T}(func::TFunc, init::T; is_valid::TIsValid=!isnothing) where {T,TFunc,TIsValid}
        new{T,TFunc,TIsValid}(func, is_valid, init, init)
    end

    # function Func(func::TFunc) where {TFunc}
    #     new{Nothing,TFunc}(func, nothing)
    # end
end

function reset!(op::Func)
	op.last_value = op.init
    nothing
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
# @inline is_valid(op::Func{T}) where {T} = !isnothing(op.last_value)
@inline is_valid(op::Func{T,TFunc,TIsValid}) where {T,TFunc,TIsValid} = op.is_valid(op.last_value)

@inline get_state(op::Func{T}) where {T} = op.last_value
