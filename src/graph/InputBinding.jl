mutable struct InputBinding{TNode}
    input_nodes::Vector{TNode}
    call_policies::Vector{CallPolicy}
    bind_as::ParamsBinding

    function InputBinding(
        nodes::Union{<:AbstractArray{TNode},<:Tuple{Vararg{TNode}}},
        call_policies::Vector{CallPolicy},
        bind_as::ParamsBinding,
    ) where {TNode}
        new{TNode}(collect(nodes), call_policies, bind_as)
    end
end

export InputBinding
