mutable struct Copy{T} <: StreamOperation
    last_value::T
    
    function Copy(init::T) where {T}
        new{T}(init)
    end
end

@inline (op::Copy{T})(executor, value::V) where {T, V} = begin
    op.last_value = copy(value)
    nothing
end

@inline is_valid(op::Copy{T}) where {T} = !isnothing(op.last_value)

@inline get_state(op::Copy{T}) where {T} = op.last_value
