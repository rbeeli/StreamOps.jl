import ShowGraphviz

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

    if !all(visited)
        msg = "Following nodes are not reachable from the source nodes, i.e. computation graph is not weakly connected: "
        for ix in findall(.!visited)
            msg *= "\n[$ix] $(graph.nodes[ix].label)"
        end
        error(msg)
    end
end

function _make_node!(
    graph::StreamGraph,
    is_source::Bool,
    operation,
    binding_mode::ParamsBinding,
    output_type::Type,
    label::Symbol
)
    # Array index of node in graph
    index = length(graph.nodes) + 1

    # Verify label is unique
    for node in graph.nodes
        node.label == label && error("Node with label '$label' already exists")
    end

    # Create node and add to graph
    node = StreamNode(index, is_source, operation, binding_mode, output_type, label)
    push!(graph.nodes, node)
    push!(graph.deps, Int[]) # The nodes that this node depends on
    push!(graph.reverse_deps, Int[]) # The nodes that depend on this node

    # Keep track of source nodes
    is_source && push!(graph.source_nodes, index)

    node
end

function source!(graph::StreamGraph, label::Symbol; out::Type{TOutput}, init::TOutput) where {TOutput}
    _make_node!(graph, true, SourceStorage{TOutput}(init), PositionParams(), TOutput, label)
end

function op!(graph::StreamGraph, label::Symbol, operation::StreamOperation; out::Type{TOutput}, params_bind=PositionParams()) where {TOutput}
    _make_node!(graph, false, operation, params_bind, TOutput, label)
end

function sink!(graph::StreamGraph, label::Symbol, operation::StreamOperation; params_bind=PositionParams())
    _make_node!(graph, false, operation, params_bind, Nothing, label)
end

function _get_call_policies(input_nodes::Vector{StreamNode}, call_policies)
    # Call policies
    policies = Vector{CallPolicy}()
    if isnothing(call_policies) || isempty(call_policies)
        # Default call policies
        if length(input_nodes) == 1
            # single input node
            push!(policies, IfExecuted(:all))
            push!(policies, IfValid(:all))
        else
            # multiple input nodes
            push!(policies, IfExecuted(:any))
            push!(policies, IfValid(:all))
        end
    else
        append!(policies, call_policies)
    end
    all(p -> p isa CallPolicy, policies) || error("Invalid call policy passed in parameter 'call_policies'")
    any(p -> p isa Never, policies) && length(policies) > 1 && error("Never policy cannot be combined with other policies")
    policies
end

function bind!(graph::StreamGraph, input_nodes, to::StreamNode; call_policies=nothing)
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
    policies = _get_call_policies(input_nodes, call_policies)

    # Create binding of single input node to target node 
    binding = InputBinding(input_nodes, policies)
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

"""
Compile the states struct for the given graph to store intermediate results
of computation steps.
"""
function compile_states_struct(::Type{TTime}, graph::StreamGraph; debug::Bool=false) where {TTime}
    # Generate a unique name for the struct
    struct_name = Symbol("GraphStates$(time_ns())")

    field_defs = []
    ctor_args = []

    push!(field_defs, :(__executed::BitVector))
    push!(ctor_args, :(falses($(length(graph.nodes)))))

    for (i, node) in enumerate(graph.nodes)
        # state value field
        # field_type = :($(Union{node.output_type,typeof(node.init_value)}))
        field_type = typeof(node.operation)
        push!(field_defs, Expr(:(::), node.field_name, field_type))
        push!(ctor_args, node.operation)

        # state time field
        push!(field_defs, Expr(:(::), Symbol("$(node.field_name)__time"), TTime))
        push!(ctor_args, :(zero($TTime)))
    end

    struct_def = Expr(:struct, true, struct_name, Expr(:block, field_defs...))
    Core.eval(@__MODULE__, struct_def)

    ctor_def = :($struct_name() = $struct_name($(ctor_args...)))
    Core.eval(@__MODULE__, ctor_def)

    debug && println("Generated states struct:")
    debug && println(struct_def)
    # println("Generated constructor:")
    # println(ctor_def)

    # function get_state(states::$struct_name, node::StreamNode)
    Core.eval(@__MODULE__, :(function did_execute(states::$struct_name, node::StreamNode)
        @inbounds states.__executed[node.index]
    end))

    # function get_state(states::$struct_name)
    Core.eval(@__MODULE__, :(function info(states::$struct_name)
        type = typeof(states)
        OrderedDict(zip(fieldnames(type), fieldtypes(type)))
    end))

    getfield(@__MODULE__, struct_name)
end

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

function _gen_execute_call!(
    executor::TExecutor,
    node_expressions::Vector{Expr},
    source_node::StreamNode,
    node::StreamNode,
    debug::Bool
) where {TExecutor<:GraphExecutor}
    tmp_exprs = Expr[]
    node_label = String(node.label)

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
                # Only trigger the node if execution was initiated by a given source node
                if call_policy.source_node != source_node
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
                    executed_exprs = [:(@inbounds states.__executed[$(node.index)]) for node in call_policy.nodes]
                    push!(call_policy_exprs, foldl((e, b) -> begin push!(e.args, b); e end, executed_exprs, init=Expr(:&&)))
                end
                has_active_bindings = true
            elseif call_policy isa IfValid
                # Only trigger the node if the connected node has a valid output
                # push!(call_policy_exprs, :(is_valid(states.$(binding.node.field_name))))
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
                    valid_exprs = [:(is_valid(states.$(node.field_name))) for node in call_policy.nodes]
                    push!(call_policy_exprs, foldl((e, b) -> begin push!(e.args, b); e end, valid_exprs, init=Expr(:&&)))
                end
                has_active_bindings = true
            elseif call_policy isa IfInvalid
                # Only trigger the node if the connected node has an invalid output
                # push!(call_policy_exprs, :(!is_valid(states.$(binding.node.field_name))))
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
                    invalid_exprs = [:(!is_valid(states.$(node.field_name))) for node in call_policy.nodes]
                    push!(call_policy_exprs, foldl((e, b) -> begin push!(e.args, b); e end, invalid_exprs, init=Expr(:&&)))
                end
                has_active_bindings = true
            else
                error("Unknown call policy for node [$node_label]: $(typeof(call_policy))")
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
        # For multiple bindings to trigger the next node, any of them can be fulfilled,
        # i.e. combine them using OR.
        exprs = foldl((e, b) -> begin push!(e.args, b); e end, binding_exe_exprs, init=Expr(:||))
        push!(tmp_exprs, :(do_execute = $exprs))
    end

    # Call node function
    # res_name = Symbol("$(node.field_name)__res")
    state_time_field = Symbol("$(node.field_name)__time")
    input_names = String[]
    input_exprs = Expr[]
    if node.binding_mode isa PositionParams
        # positional parameters
        # input_exprs = (:(get_state(states.$(input.node.field_name))) for input in node.inputs)
        for input_binding in node.input_bindings
            for input in input_binding.input_nodes
                push!(input_exprs, :(get_state(states.$(input.field_name))))
                push!(input_names, String(input.field_name))
            end
        end
        # call_expr = :(states.$(node.field_name)(executor, $(input_exprs...)))
    elseif node.binding_mode isa NamedParams
        # keyword parameters
        # generates tuples of (input_name, input_value)
        # input_exprs = ((input.node.field_name, :(get_state(states.$(input.node.field_name)))) for input in node.inputs)
        for input_binding in node.input_bindings
            for input in input_binding.input_nodes
                push!(input_exprs, Expr(:kw, input.field_name, :(get_state(states.$(input.field_name)))))
                push!(input_names, String(input.field_name))
            end
        end
        # call_expr = Expr(:call, :(states.$(node.field_name)), :(executor), (Expr(:kw, k, v) for (k, v) in input_exprs)...)
    elseif node.binding_mode isa TupleParams
        # pack all input values into single tuple parameter
        # input_exprs = (:(get_state(states.$(input.node.field_name))) for input in node.inputs)
        tuple_exprs = Expr[]
        for input_binding in node.input_bindings
            for input in input_binding.input_nodes
                push!(tuple_exprs, :(get_state(states.$(input.field_name))))
                push!(input_names, String(input.field_name))
            end
        end
        push!(input_exprs, :(($(tuple_exprs...),)))
        # call_expr = :(states.$(node.field_name)(executor, ($(input_exprs...),)))
    else
        error("Unknown parameter binding for node [$node_label]: $(typeof(node.binding_mode))")
    end

    call_expr = :(states.$(node.field_name)(executor, $(input_exprs...)))

    result_expr = if debug
        :(
            if do_execute
                states.$state_time_field = time(executor)
                @inbounds states.__executed[$(node.index)] = true
                try
                    println("Executing node [$($node_label)] at time $(time(executor))...")
                    $call_expr
                catch e
                    println("Error in node [$($node_label)] with input nodes [$(join(input_names, ","))] at time $(time(executor)): $e")
                    throw(e)
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
    # push!(node_expressions, :($res_name = $result_expr))
    push!(tmp_exprs, :($result_expr))

    # # Store execution result in state variables
    # # push!(node_expressions, :(if !isnothing($res_name)
    # push!(tmp_exprs, :(
    #     # if !isnothing($res_name)
    #         # # update state value of node
    #         # states.$(node.field_name) = $res_name
    #         # update state time of node
    #         states.$state_time_field = time(executor)
    #     # end
    # ))

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
    node_expressions = Expr[]

    # reset all __executed flags
    push!(node_expressions, :(fill!(states.__executed, false)))

    # Save value in source storage
    push!(node_expressions, :(states.$(source_node.field_name)(executor, event_value)))

    # Mark the source node as executed
    push!(node_expressions, :(@inbounds states.__executed[$(source_node.index)] = true))

    for (i, node_index) in enumerate(subgraph_indices[2:end])
        node = nodes[node_index]
        field_name = node.field_name

        debug && println("\nNode [$(node.label)] index=$(node.index) output_type=$(node.output_type)")

        # Generate code to execute the node
        _gen_execute_call!(executor, node_expressions, source_node, node, debug)
    end

    func_expression = :(function (executor::$TExecutor, event_value::$(source_node.output_type))
        states = executor.states

        # Execute all expressions for the subgraph
        $(node_expressions...)

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

function graphviz(
    graph::StreamGraph;
    nodefontsize=10,
    edgefontsize=8,
    nodefontname="Helvetica,Arial,sans-serif",
    edgefontname="Helvetica,Arial,sans-serif"
)
    io = IOBuffer()
    
    println(io, "digraph G {")
    println(io, "  node [fontsize=$nodefontsize fontname=\"$nodefontname\"];")
    println(io, "  edge [fontsize=$edgefontsize fontname=\"$edgefontname\" fontcolor=\"#666666\"];")
    
    function make_label(node::StreamNode)
        return "$(node.label)<FONT POINT-SIZE=\"5\">&nbsp;</FONT><SUP><FONT COLOR=\"gray\" POINT-SIZE=\"$(ceil(Int, 0.7nodefontsize))\">[$(node.index)]</FONT></SUP>"
    end

    # Source nodes (at the top)
    println(io, "  { rank=source; ")
    for node in filter(is_source, graph.nodes)
        println(io, "    node$(node.index) [label=<$(make_label(node))> shape=ellipse color=blue penwidth=0.75];")
    end
    println(io, "  }")

    # Computation nodes
    for node in graph.nodes
        if !is_source(node) && !is_sink(node)
            println(io, "  node$(node.index) [label=<$(make_label(node))> shape=ellipse color=black penwidth=0.75];")
        end
    end

    # Sink nodes (at the bottom)
    println(io, "  { rank=sink; ")
    for node in filter(is_sink, graph.nodes)
        println(io, "    node$(node.index) [label=<$(make_label(node))> shape=ellipse color=green penwidth=1];")
    end
    println(io, "  }")
    
    # Add edges to the graph
    for (i, node) in enumerate(graph.nodes)
        edge_counter = 1
        for input_binding in node.input_bindings
            for input_node in input_binding.input_nodes
                headlabel = length(input_binding.input_nodes) > 1 ? "headlabel=<<FONT POINT-SIZE=\"$(ceil(Int, 0.6nodefontsize))\">$(edge_counter).</FONT>>" : ""
                if first(input_binding.call_policies) isa Never
                    # input has no call policies, i.e. it does never trigger the node
                    println(io, "  node$(input_node.index) -> node$(node.index) [label=<&nbsp;Never> $headlabel color=gray style=dotted arrowhead=open penwidth=1 arrowsize=0.75 labeldistance=1.5];")
                else
                    label = join(graphviz_label.(input_binding.call_policies), "</TD></TR><TR><TD ALIGN=\"LEFT\">&nbsp;")
                    println(io, "  node$(input_node.index) -> node$(node.index) [label=<
                        <TABLE BORDER=\"0\" CELLBORDER=\"0\" CELLSPACING=\"0\" CELLPADDING=\"0\">
                            <TR><TD ALIGN=\"LEFT\">&nbsp;$label</TD></TR>
                        </TABLE>> arrowhead=open penwidth=0.5 arrowsize=0.75 labeldistance=1.5 $headlabel];")
                end
                edge_counter += 1
            end
        end
    end
    
    println(io, "}") # end digraph
    
    dot_code = String(take!(io))
    ShowGraphviz.DOT(dot_code)
end