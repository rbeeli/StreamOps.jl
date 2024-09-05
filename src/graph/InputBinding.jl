mutable struct InputBinding{TNode}
    input_nodes::Vector{TNode}
    call_policies::Vector{CallPolicy}
    bind_as::ParamsBinding
    function InputBinding(nodes::Vector{TNode}, call_policies::Vector{CallPolicy}, bind_as::ParamsBinding) where {TNode}
        new{TNode}(nodes, call_policies, bind_as)
    end
end
