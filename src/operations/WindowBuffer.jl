using DataStructures

"""
Maintains a rolling window of the last `window_size` values
using an efficient circular buffer with O(1) push and pop operations.

# Arguments
- `window_size::Int`: The size of the window to maintain.
- `copy::Bool=false`: If `true`, the result will be a copy of the data as `Vector{In}`,
    otherwise it will be a `view` into the underlying buffer.

The implementation is based on [DataStructures.jl](https://juliacollections.github.io/DataStructures.jl/latest/)'s [CircularBuffer](https://juliacollections.github.io/DataStructures.jl/latest/circ_buffer/).
    
Note that the returned value is a view into the buffer, so it is not a copy of the data,
hence the result should not be modified or stored for later use.
If temporary storage of the result or modification of the values is needed, a copy should be made.
"""
mutable struct WindowBuffer{T,copy} <: StreamOperation
    const buffer::CircularBuffer{T}
    const copy::Bool

    function WindowBuffer{T}(window_size::Int; copy::Bool=false) where {T}
        buffer = CircularBuffer{T}(window_size)
        new{T,copy}(buffer, copy)
    end
end

operation_output_type(op::WindowBuffer{T,false}) where {T} = typeof(view(op.buffer, :))
operation_output_type(::WindowBuffer{T,true}) where {T} = Vector{T}

function reset!(op::WindowBuffer)
    empty!(op.buffer)
    nothing
end

@inline function (op::WindowBuffer{T})(executor, value::T) where {T}
    # automatically handles overwriting in a circular manner
    push!(op.buffer, value)
    nothing
end

@inline is_valid(op::WindowBuffer) = isfull(op.buffer)

@inline function get_state(op::WindowBuffer{T,false}) where {T}
    view(op.buffer, :)
end

@inline function get_state(op::WindowBuffer{T,true}) where {T}
    collect(op.buffer)
end

@inline Base.length(op::WindowBuffer) = length(op.buffer)

export WindowBuffer
