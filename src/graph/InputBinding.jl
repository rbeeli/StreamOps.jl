mutable struct InputBinding{TNode}
    input_nodes::Vector{TNode}
    call_policies::Vector{CallPolicy}
    params_bind::ParamsBinding
    function InputBinding(nodes::Vector{TNode}, call_policies::Vector{CallPolicy}, params_bind::ParamsBinding) where {TNode}
        new{TNode}(nodes, call_policies, params_bind)
    end
end
