mutable struct Func{T,TFunc} <: StreamOperation
    const func::TFunc
    last_value::T

    function Func(func::TFunc, init::T) where {T,TFunc}
        new{T,TFunc}(func, init)
    end

    function Func{T}(func::TFunc, init::T) where {T,TFunc}
        new{T,TFunc}(func, init)
    end
    
    function Func(func::TFunc) where {TFunc}
        new{Nothing,TFunc}(func, nothing)
    end
end

@inline (op::Func{Nothing,TFunc})(args...; kwargs...) where {TFunc} = begin
    op.func(args...; kwargs...)
    nothing
end

@inline (op::Func{T,TFunc})(args...; kwargs...) where {T,TFunc} = begin
    op.last_value = op.func(args...; kwargs...)
    nothing
end

@inline is_valid(op::Func{T}) where {T} = !isnothing(op.last_value)

@inline get_state(op::Func{T}) where {T} = op.last_value
