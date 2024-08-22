# If connected node is executed, always trigger the node
struct Always <: CallPolicy
end

# Never trigger the node (passive, input only)
struct Never <: CallPolicy
end

# Only trigger node if execution was initiated by a given source node
struct IfSource{TNode} <: CallPolicy
    source_node::TNode
    function IfSource(node::TNode) where {TNode}
        is_source(node) || error("Node [$(label(node))] is not a source node")
        new{TNode}(node)
    end
end

# If connected node is executed, REGARDLESS of valid output or not, trigger the node
struct IfExecuted{TNode} <: CallPolicy
    nodes::Union{Symbol,Vector{TNode}} # :any, :all
    function IfExecuted(mode::Symbol=:all)
        mode ∈ (:any, :all) || error("Invalid mode '$mode' for IfExecuted")
        new{Nothing}(mode)
    end
    IfExecuted(nodes::TNode...) where {TNode} = new{TNode}(collect(nodes))
end

# If connected node(s) have valid output(s), trigger the node
struct IfValid{TNode} <: CallPolicy
    nodes::Union{Symbol,Vector{TNode}} # :any, :all
    function IfValid(mode::Symbol=:all)
        mode ∈ (:any, :all) || error("Invalid mode '$mode' for IfValid")
        new{Nothing}(mode)
    end
    IfValid(nodes::TNode...) where {TNode} = new{TNode}(collect(nodes))
end

# If connected node(s) have invalid output(s), trigger the node
struct IfInvalid{TNode} <: CallPolicy
    nodes::Union{Symbol,Vector{TNode}} # :any, :all
    function IfInvalid(mode::Symbol=:any)
        mode ∈ (:any, :all) || error("Invalid mode '$mode' for IfInvalid")
        new{Nothing}(mode)
    end
    IfInvalid(nodes::TNode...) where {TNode} = new{TNode}(collect(nodes))
end

function _make_label(nodes::Union{Symbol,Vector{TNode}}) where {TNode}
    return if nodes isa Symbol
        ":$nodes"
    else
        join([label(node) for node in nodes], ",")
    end
end

graphviz_label(policy::Always) = "Always"
graphviz_label(policy::Never) = "Never"
graphviz_label(policy::IfSource) = "IfSource($(label(policy.source_node)))"
graphviz_label(policy::IfExecuted) = "IfExecuted($(_make_label(policy.nodes)))"
graphviz_label(policy::IfValid) = "IfValid($(_make_label(policy.nodes)))"
graphviz_label(policy::IfInvalid) = "IfInvalid($(_make_label(policy.nodes)))"
