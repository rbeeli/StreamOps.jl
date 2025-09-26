# If connected node is executed, always trigger the node
struct Always <: CallPolicy end

# Never trigger the node (passive, input only)
struct Never <: CallPolicy end

# Only trigger node if execution was initiated by a given source node
struct IfSource <: CallPolicy
    source_node::Symbol

    IfSource(source_node::Symbol) = new(source_node)
    IfSource(source_node::String) = new(Symbol(source_node))
end

# If connected node was executed, REGARDLESS of valid output or not, trigger the node
struct IfExecuted <: CallPolicy
    nodes::Union{Symbol,Vector{Symbol}} # :any, :all or node label symbols

    # Primary constructor
    function IfExecuted(node::Union{Symbol,String}=:all)
        if node isa String
            node = Symbol(node)
        end
        node ∈ (:any, :all) && return new(node)
        new([node])
    end

    function IfExecuted(nodes::Union{Tuple{Vararg{T}},Vector{T}}) where {T<:Union{Symbol,String}}
        new([Symbol(x) for x in nodes])
    end
end

# Outer constructors
IfExecuted(nodes::Union{Symbol,String}...) = IfExecuted(nodes)

# # If connected node was NOT executed, REGARDLESS of valid output or not, trigger the node
# struct IfNotExecuted <: CallPolicy
#     nodes::Union{Symbol,Vector{Symbol}} # :any, :all or node label symbols
#     function IfNotExecuted(mode::Symbol=:all)
#         mode ∈ (:any, :all) && return new(mode)
#         new([mode])
#     end
#     IfNotExecuted(nodes::Symbol...) = new(collect(nodes))
# end

# If connected node(s) have valid output(s), trigger the node
struct IfValid <: CallPolicy
    nodes::Union{Symbol,Vector{Symbol}} # :any, :all or node label symbols

    # Primary constructor
    function IfValid(node::Union{Symbol,String}=:all)
        if node isa String
            node = Symbol(node)
        end
        node ∈ (:any, :all) && return new(node)
        new([node])
    end

    function IfValid(nodes::Union{Tuple{Vararg{T}},Vector{T}}) where {T<:Union{Symbol,String}}
        new([Symbol(x) for x in nodes])
    end
end

# Outer constructors
IfValid(nodes::Union{Symbol,String}...) = IfValid(nodes)

# If connected node(s) have invalid output(s), trigger the node
struct IfInvalid <: CallPolicy
    nodes::Union{Symbol,Vector{Symbol}} # :any, :all or node label symbols

    # Primary constructor
    function IfInvalid(node::Union{Symbol,String}=:any)
        if node isa String
            node = Symbol(node)
        end
        node ∈ (:any, :all) && return new(node)
        new([node])
    end

    function IfInvalid(nodes::Union{Tuple{Vararg{T}},Vector{T}}) where {T<:Union{Symbol,String}}
        new([Symbol(x) for x in nodes])
    end
end

# Outer constructors
IfInvalid(nodes::Union{Symbol,String}...) = IfInvalid(nodes)

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
# graphviz_label(policy::IfNotExecuted) = "IfNotExecuted($(_make_label(policy.nodes)))"
graphviz_label(policy::IfValid) = "IfValid($(_make_label(policy.nodes)))"
graphviz_label(policy::IfInvalid) = "IfInvalid($(_make_label(policy.nodes)))"

export Always, Never, IfSource, IfExecuted, IfValid, IfInvalid, graphviz_label
