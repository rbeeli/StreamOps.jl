mutable struct InputBinding{TNode}
    input_nodes::Vector{TNode}
    call_policies::Vector{CallPolicy}
    function InputBinding(nodes::Vector{TNode}, call_policies::Vector{CallPolicy}) where {TNode}
        new{TNode}(nodes, call_policies)
    end
end
