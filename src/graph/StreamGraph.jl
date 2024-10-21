"""
A directed acyclic graph (DAG) that represents a stream computation graph.
"""
mutable struct StreamGraph
    nodes::Vector{StreamNode}
    source_nodes::Vector{Int}
    deps::Vector{Vector{Int}}
    reverse_deps::Vector{Vector{Int}}
    topo_order::Vector{Int}
    function StreamGraph()
        new(Vector{StreamNode}(),
            Int[],
            Vector{Int}[],
            Vector{Int}[],
            Int[])
    end
end

"""
Sort the nodes in the graph in topological order using a depth-first search (DFS).
"""
function topological_sort!(graph::StreamGraph)
    empty!(graph.topo_order)
    visited = falses(length(graph.nodes))
    temp_stack = Int[]

    for node_index in 1:length(graph.nodes)
        if !visited[node_index]
            push!(temp_stack, node_index)

            while !isempty(temp_stack)
                current_node = temp_stack[end]

                if !visited[current_node]
                    visited[current_node] = true
                    push!(graph.topo_order, current_node)
                end

                all_visited = true

                for dependent_index in graph.deps[current_node]
                    if !visited[dependent_index]
                        push!(temp_stack, dependent_index)
                        all_visited = false
                    end
                end

                if all_visited
                    pop!(temp_stack)
                end
            end
        end
    end

    if length(graph.topo_order) != length(graph.nodes)
        error("Graph has a cycle")
    end

    nothing
end

"""
Check if the graph is weakly connected, i.e., there is a path between every pair of nodes.
If not, the graph is not fully connected and some nodes will never be reached.

Also check that there is at least one source node in the graph.
"""
function verify_graph(graph::StreamGraph)
    isempty(graph.nodes) && error("Empty graph.")
    isempty(graph.source_nodes) && error("No source nodes in the graph.")

    visited = falses(length(graph.nodes))
    stack = copy(graph.source_nodes)

    # Mark all source nodes as visited
    for source in stack
        visited[source] = true
    end

    # Perform DFS from all source nodes
    while !isempty(stack)
        node_index = pop!(stack)

        for ix in graph.reverse_deps[node_index]
            if !visited[ix]
                visited[ix] = true
                push!(stack, ix)
            end
        end
    end

    # only nodes of type Constant{T} are allowed to have no input bindings
    unvisited = findall(i -> !visited[i] & !isa(graph.nodes[i].operation, Constant), eachindex(visited))
    if any(unvisited)
        msg = "Following nodes are not reachable from the source nodes, i.e. computation graph is not weakly connected: "
        for ix in unvisited
            msg *= "\n [$ix] $(graph.nodes[ix].label)"
        end
        error(msg)
    end
end

function _make_node!(
    graph::StreamGraph,
    is_source::Bool,
    is_sink::Bool,
    operation,
    output_type::Type,
    label::Symbol
)
    label ∈ [:all, :any] && error("Invalid node label '$label'")

    # Array index of node in graph
    index = length(graph.nodes) + 1

    # Verify label is unique
    for node in graph.nodes
        node.label == label && error("Node with label '$label' already exists")
    end

    # Create node and add to graph
    node = StreamNode(index, is_source, is_sink, operation, output_type, label)
    push!(graph.nodes, node)
    push!(graph.deps, Int[]) # The nodes that this node depends on
    push!(graph.reverse_deps, Int[]) # The nodes that depend on this node

    # Keep track of source nodes
    is_source && push!(graph.source_nodes, index)

    node
end

function source!(graph::StreamGraph, label::Symbol; out::Type{TOutput}, init::TOutput) where {TOutput}
    _make_node!(graph, true, false, AdapterStorage{TOutput}(init), TOutput, label)
end

function op!(graph::StreamGraph, label::Symbol, operation::StreamOperation; out::Type{TOutput}) where {TOutput}
    _make_node!(graph, false, false, operation, TOutput, label)
end

function sink!(graph::StreamGraph, label::Symbol, operation::StreamOperation)
    _make_node!(graph, false, true, operation, Nothing, label)
end

function _get_call_policies(graph::StreamGraph, input_nodes::Vector{StreamNode}, call_policies)
    policies = Vector{CallPolicy}()
    if isnothing(call_policies) || isempty(call_policies)
        # Default call policies
        push!(policies, IfExecuted(:any))
        push!(policies, IfValid(:all))
    else
        append!(policies, call_policies)
    end
    all(p -> p isa CallPolicy, policies) || error("Invalid call policy passed in parameter 'call_policies'")
    any(p -> p isa Never, policies) && length(policies) > 1 && error("Never policy cannot be combined with other policies")
    policies
end

# function _get_validation_policies(graph::StreamGraph, input_nodes::Vector{StreamNode}, val_policies)
#     policies = Vector{CallPolicy}()
#     if isnothing(val_policies) || isempty(val_policies)
#         # Default validation policies
#         push!(policies, IfValid(:all))
#     else
#         append!(policies, val_policies)
#     end
#     all(p -> p isa CallPolicy, policies) || error("Invalid validation policy passed in parameter 'val_policies'")
#     any(p -> p isa Never, policies) && length(policies) > 1 && error("Never policy cannot be combined with other policies")
#     policies
# end

function bind!(
    graph::StreamGraph,
    input_nodes,
    to::Symbol
    ;
    call_policies=nothing,
    val_policies=nothing,
    bind_as=PositionParams()
)
    if input_nodes isa Symbol
        input_nodes = [input_nodes]
    end
    bind!(
        graph,
        get_node.(Ref(graph), input_nodes),
        get_node(graph, to),
        call_policies=call_policies,
        val_policies=val_policies,
        bind_as=bind_as)
end

function bind!(
    graph::StreamGraph,
    input_nodes,
    to::StreamNode
    ;
    call_policies=nothing,
    val_policies=nothing,
    bind_as=PositionParams()
)
    call_policies isa CallPolicy && (call_policies = [call_policies])
    val_policies isa CallPolicy && (val_policies = [val_policies])

    if input_nodes isa StreamNode
        input_nodes = [input_nodes]
    else
        input_nodes = collect(input_nodes)
    end

    # Verify parameters
    is_source(to) && error("Cannot bind input [$(input.label)] to a source node [$(to.label)]")
    to in graph.nodes || error("Target node [$(to.label)] not found in graph")
    for input in input_nodes
        is_sink(input) && error("Cannot bind sink node [$(input.label)] as input")
        input in graph.nodes || error("Input node [$(input.label)] not found in graph")
        input.index != to.index || error("Cannot bind node [$(input.label)] to itself")
        input.index in graph.deps[to.index] && error("Node [$(input.label)] is already bound to node [$(to.label)]")
    end

    # Call policies
    policies1 = _get_call_policies(graph, input_nodes, call_policies)

    # Create binding of single input node to target node 
    binding = InputBinding(input_nodes, policies1, bind_as)
    push!(to.input_bindings, binding)
    for input in input_nodes
        push!(graph.deps[to.index], input.index)
        push!(graph.reverse_deps[input.index], to.index)
    end
    
    binding
end

function get_source_subgraph(graph::StreamGraph, source_node::StreamNode)
    subgraph_indices = Int[]
    queue = [source_node.index]
    visited = falses(length(graph.nodes))

    while !isempty(queue)
        node_index = popfirst!(queue)
        if !visited[node_index]
            push!(subgraph_indices, node_index)
            visited[node_index] = true
            append!(queue, graph.reverse_deps[node_index])
        end
    end

    # Sort the subgraph indices according to the topological order
    sort!(subgraph_indices, by=i -> graph.topo_order[i])

    subgraph_indices
end

@inline get_node(graph::StreamGraph, index::Int) = @inbounds graph.nodes[index]

@inline get_node_label(graph::StreamGraph, index::Int) = @inbounds label(graph.nodes[index])

# TODO: Optimize this function
@inline function get_node(graph::StreamGraph, label::Symbol)
    ix = findfirst(n -> n.label == label, graph.nodes)
    isnothing(ix) && error("Node with label '$label' not found")
    @inbounds graph.nodes[ix]
end

@inline Base.getindex(graph::StreamGraph, label::Symbol) = get_node(graph, label)

function compile_graph!(::Type{TTime}, g::StreamGraph; debug::Bool=false) where {TTime}
    # verify that the graph is weakly connected and has at least one source node
    verify_graph(g)

    # sort computation graph nodes in topological order
    topological_sort!(g)

    # compile states struct
    states_type = compile_states_struct(TTime, g; debug=debug)

    # use invokelatest to call the generated states type constructor,
    # otherwise a world age error will occur because the constructor
    # is defined after the call
    states = Base.invokelatest(states_type)

    states
end

function _gen_params_exprs(node)
    input_names = String[]
    input_exprs = Expr[]

    for input_binding in node.input_bindings
        if input_binding.bind_as isa PositionParams
            # positional parameters
            for input in input_binding.input_nodes
                push!(input_exprs, :(get_state(states.$(input.field_name))))
                push!(input_names, String(input.field_name))
            end
        elseif input_binding.bind_as isa NamedParams
            # keyword parameters - generates tuples of (input_name, input_value)
            for input in input_binding.input_nodes
                push!(input_exprs, Expr(:kw, input.field_name, :(get_state(states.$(input.field_name)))))
                push!(input_names, String(input.field_name))
            end
        elseif input_binding.bind_as isa TupleParams
            # pack all input values into single tuple parameter
            tuple_exprs = Expr[]
            for input in input_binding.input_nodes
                push!(tuple_exprs, :(get_state(states.$(input.field_name))))
                push!(input_names, String(input.field_name))
            end
            push!(input_exprs, :(($(tuple_exprs...),)))
        elseif input_binding.bind_as isa NoBind
            # no input binding
            nothing
        else
            error("Unsupported parameter binding for node [$(label(node))]: $(typeof(input_binding.bind_as))")
        end
    end

    input_names, input_exprs
end

function _gen_execute_call!(
    executor::TExecutor,
    node_expressions::Vector{Expr},
    source_node::StreamNode,
    node::StreamNode,
    debug::Bool
) where {TExecutor<:GraphExecutor}
    g = executor.graph
    tmp_exprs = Expr[]

    # Input bindings
    has_active_bindings = false
    binding_exe_exprs = Expr[]
    for binding in node.input_bindings
        binding_nodes = binding.input_nodes
        debug && println("- input binding [$(join([label(node) for node in binding_nodes], ","))]")
        
        call_policy_exprs = Expr[]
        for call_policy in binding.call_policies
            debug && println("  | call_policy: $(typeof(call_policy))")
            if call_policy isa Always
                # Always trigger the node, regardless of the connected nodes' state
                has_active_bindings = true
                continue
            elseif call_policy isa Never
                # Never trigger the node by this binding
                break
            elseif call_policy isa IfSource
                policy_node = g[call_policy.source_node]
                is_source(policy_node) || error("Node [$(call_policy.source_node)] not a source node")

                # Only trigger the node if execution was initiated by a given source node
                if policy_node != source_node
                    return nothing # Skip execution
                end
                has_active_bindings = true
            elseif call_policy isa IfExecuted
                # Only trigger the node if the connected node(s) have been executed in current pass
                if call_policy.nodes == :any
                    # Any of the connected nodes must have been executed
                    executed_exprs = [:(@inbounds states.__executed[$(node.index)]) for node in binding_nodes]
                    push!(call_policy_exprs, foldl((e, b) -> begin push!(e.args, b); e end, executed_exprs, init=Expr(:||)))
                elseif call_policy.nodes == :all
                    # All of the connected nodes must have been executed
                    executed_exprs = [:(@inbounds states.__executed[$(node.index)]) for node in binding_nodes]
                    push!(call_policy_exprs, foldl((e, b) -> begin push!(e.args, b); e end, executed_exprs, init=Expr(:&&)))
                else
                    # Specific nodes must have been executed
                    policy_nodes = [get_node(g, node) for node in call_policy.nodes]
                    executed_exprs = [:(@inbounds states.__executed[$(node.index)]) for node in policy_nodes]
                    push!(call_policy_exprs, foldl((e, b) -> begin push!(e.args, b); e end, executed_exprs, init=Expr(:&&)))
                end
                has_active_bindings = true
            elseif call_policy isa IfValid
                # Only trigger the node if the connected node has a valid output
                if call_policy.nodes == :any
                    # Any of the connected nodes must have a valid output
                    valid_exprs = [:(is_valid(states.$(node.field_name))) for node in binding_nodes]
                    push!(call_policy_exprs, foldl((e, b) -> begin push!(e.args, b); e end, valid_exprs, init=Expr(:||)))
                elseif call_policy.nodes == :all
                    # All of the connected nodes must have a valid output
                    valid_exprs = [:(is_valid(states.$(node.field_name))) for node in binding_nodes]
                    push!(call_policy_exprs, foldl((e, b) -> begin push!(e.args, b); e end, valid_exprs, init=Expr(:&&)))
                else
                    # Specific nodes must have a valid output
                    policy_nodes = [get_node(g, node) for node in call_policy.nodes]
                    valid_exprs = [:(is_valid(states.$(node.field_name))) for node in policy_nodes]
                    push!(call_policy_exprs, foldl((e, b) -> begin push!(e.args, b); e end, valid_exprs, init=Expr(:&&)))
                end
                has_active_bindings = true
            elseif call_policy isa IfInvalid
                # Only trigger the node if the connected node has an invalid output
                if call_policy.nodes == :any
                    # Any of the connected nodes must have an invalid output
                    invalid_exprs = [:(!is_valid(states.$(node.field_name))) for node in binding_nodes]
                    push!(call_policy_exprs, foldl((e, b) -> begin push!(e.args, b); e end, invalid_exprs, init=Expr(:||)))
                elseif call_policy.nodes == :all
                    # All of the connected nodes must have an invalid output
                    invalid_exprs = [:(!is_valid(states.$(node.field_name))) for node in binding_nodes]
                    push!(call_policy_exprs, foldl((e, b) -> begin push!(e.args, b); e end, invalid_exprs, init=Expr(:&&)))
                else
                    # Specific nodes must have an invalid output
                    policy_nodes = [get_node(g, node) for node in call_policy.nodes]
                    invalid_exprs = [:(!is_valid(states.$(node.field_name))) for node in policy_nodes]
                    push!(call_policy_exprs, foldl((e, b) -> begin push!(e.args, b); e end, invalid_exprs, init=Expr(:&&)))
                end
                has_active_bindings = true
            else
                error("Unknown call policy for node [$(label(node))]: $(typeof(call_policy))")
            end
        end

        if length(call_policy_exprs) == 1
            push!(binding_exe_exprs, first(call_policy_exprs))
        elseif length(call_policy_exprs) > 1
            # For a single binding to trigger the next node, all its call policies must be fulfilled,
            # i.e. combine them using AND.
            exprs = foldl((e, b) -> begin push!(e.args, b); e end, call_policy_exprs, init=Expr(:&&))
            push!(binding_exe_exprs, :($exprs))
        end
    end

    if !has_active_bindings
        # No input bindings, never executed
        return nothing
    end

    if length(binding_exe_exprs) == 0
        push!(tmp_exprs, :(do_execute = true))
    elseif length(binding_exe_exprs) == 1
        # Single do_execute expression
        push!(tmp_exprs, :(do_execute = $(first(binding_exe_exprs))))
    else
        # For multiple bindings to trigger the next node, any of them may be fulfilled,
        # i.e. use OR condition.
        exprs = foldl((e, b) -> begin push!(e.args, b); e end, binding_exe_exprs, init=Expr(:||))
        push!(tmp_exprs, :(do_execute = $exprs))
    end

    # Generate function call parameter expressions
    input_names, input_exprs = _gen_params_exprs(node)

    if node.operation isa Func
        # Directly call func for Func operation (skip functor indirection)
        if has_output(node.operation)
            call_expr = :(states.$(node.field_name).last_value = states.$(node.field_name).func(executor, $(input_exprs...)))
        else
            call_expr = :(states.$(node.field_name).func(executor, $(input_exprs...)))
        end
    else
        # Not a Func operation, call functor
        call_expr = :(states.$(node.field_name)(executor, $(input_exprs...)))
    end

    state_time_field = Symbol("$(node.field_name)__time")
    result_expr = if debug
        :(
            if do_execute
                states.$state_time_field = time(executor)
                @inbounds states.__executed[$(node.index)] = true
                try
                    println("Executing node [$($("$(label(node))"))] at time $(time(executor))...")
                    $call_expr
                catch e
                    msg = "Execution of node [$($("$(label(node))"))] with inputs [$(join($(input_names), ","))] at time $(time(executor)) failed."
                    throw(StreamOpsError(Symbol($("$(label(node))")), msg, e))
                end
            end
        )
    else
        :(
            if do_execute
                states.$state_time_field = time(executor)
                @inbounds states.__executed[$(node.index)] = true
                $call_expr
            end
        )
    end
    push!(tmp_exprs, :($result_expr))

    # append all expressions to the node expressions
    append!(node_expressions, tmp_exprs)

    nothing
end

function compile_source!(executor::TExecutor, source_node::StreamNode; debug=false) where {TExecutor<:GraphExecutor}
    graph = executor.graph
    nodes = graph.nodes

    debug && println("-------------------------------------------")
    debug && println("Compiling source node [$(source_node.label)]")

    # Find subgraph starting from given source node.
    # Nodes are returned in topological order (DFS).
    subgraph_indices = get_source_subgraph(graph, source_node)

    # Generate code for each node in the subgraph.
    # The code is generated in a block of expressions that are executed sequentially.
    exec_exprs = Expr[]

    # reset all __executed flags
    push!(exec_exprs, :(fill!(states.__executed, false)))

    # Save value in source storage
    push!(exec_exprs, :(states.$(source_node.field_name)(executor, event_value)))

    # Mark the source node as executed
    push!(exec_exprs, :(@inbounds states.__executed[$(source_node.index)] = true))

    # Execute all expressions for the subgraph
    for (i, node_index) in enumerate(subgraph_indices[2:end])
        node = nodes[node_index]

        debug && println("\nNode [$(node.label)] index=$(node.index) output_type=$(node.output_type)")

        # Generate code to execute the node
        _gen_execute_call!(executor, exec_exprs, source_node, node, debug)
    end

    # Generate time sync calls.
    # If a node is only an input-node for any node in the current
    # subgraph, it would otherwise not update its time and drop old records.
    time_sync_nodes = filter(n -> OperationTimeSync(n.operation), nodes)
    time_sync_exprs = Expr[]
    for node in time_sync_nodes
        push!(time_sync_exprs, :(
            # if !(@inbounds states.__executed[$(node.index)])
            update_time!(states.$(node.field_name), time(executor))
            # end
        ))
    end
    debug && println("\nTime sync nodes: $(join([label(node) for node in time_sync_nodes], ","))")

    func_expression = :(function (executor::$TExecutor, event_value::$(source_node.output_type))
        states = executor.states

        # Time synchronization
        $(time_sync_exprs...)

        # Execute all expressions for the subgraph
        $(exec_exprs...)

        nothing
    end)

    # Create the compiled function
    compiled_func = @eval $func_expression

    # Print the clean version of the generated code
    if debug
        println("\nGenerated code: ")
        _print_expression(func_expression)
        println()
    end

    compiled_func
end
