# If connected node is executed, always trigger the node
struct Always <: CallPolicy
end

# Never trigger the node (passive, input only)
struct Never <: CallPolicy
end

# Only trigger node if execution was initiated by a given source node
struct IfSource <: CallPolicy
    source_node::Symbol
end

# If connected node is executed, REGARDLESS of valid output or not, trigger the node
struct IfExecuted <: CallPolicy
    nodes::Union{Symbol,Vector{Symbol}} # :any, :all or node label symbols
    function IfExecuted(mode::Symbol=:all)
        mode ∈ (:any, :all) && return new(mode)
        new([mode])
    end
    IfExecuted(nodes::Symbol...) = new(collect(nodes))
end

# If connected node(s) have valid output(s), trigger the node
struct IfValid <: CallPolicy
    nodes::Union{Symbol,Vector{Symbol}} # :any, :all or node label symbols
    function IfValid(mode::Symbol=:all)
        mode ∈ (:any, :all) && return new(mode)
        new([mode])
    end
    IfValid(nodes::Symbol...) = new(collect(nodes))
end

# If connected node(s) have invalid output(s), trigger the node
struct IfInvalid <: CallPolicy
    nodes::Union{Symbol,Vector{Symbol}} # :any, :all or node label symbols
    function IfInvalid(mode::Symbol=:any)
        mode ∈ (:any, :all) && return new(mode)
        new([mode])
    end
    IfInvalid(nodes::Symbol...) = new(collect(nodes))
end

function _make_label(nodes::Union{Symbol,Vector{Symbol}})
    return if nodes isa Symbol
        ":$nodes"
    else
        join([string(node) for node in nodes], ",")
    end
end

graphviz_label(policy::Always) = "Always"
graphviz_label(policy::Never) = "Never"
graphviz_label(policy::IfSource) = "IfSource($(_make_label(policy.source_node)))"
graphviz_label(policy::IfExecuted) = "IfExecuted($(_make_label(policy.nodes)))"
graphviz_label(policy::IfValid) = "IfValid($(_make_label(policy.nodes)))"
graphviz_label(policy::IfInvalid) = "IfInvalid($(_make_label(policy.nodes)))"
