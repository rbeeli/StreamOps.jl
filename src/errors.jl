struct StreamOpsError <: Exception
    node_label::Symbol
    message::String
    inner_exception::Union{Exception,Nothing}

    function StreamOpsError(node_label::Symbol, message::String, inner_exception=nothing)
        new(node_label, message, inner_exception)
    end
end

function Base.showerror(io::IO, e::StreamOpsError)
    print(io, "StreamOpsError at node [", e.node_label, "]: ", e.message, " ")
    if !isnothing(e.inner_exception)
        print(io, "Inner exception: ")
        showerror(io, e.inner_exception)
    end
end

export StreamOpsError
