using DataStructures: OrderedDict

const TIME_FIELD_SUFFIX = "__time"

struct InterpretedGraphState{TTime} <: GraphState
    operations::Vector{Any}
    times::Vector{TTime}
    executed::BitVector
    labels::Vector{Symbol}
    index_by_label::Dict{Symbol,Int}
end

struct PreparedPolicyData
    kind::Symbol
    mode::Symbol
    node_indices::Vector{Int}
    field_names::Vector{Symbol}
    source_index::Int
end

struct PreparedBindingData
    bind_as::ParamsBinding
    input_indices::Vector{Int}
    input_field_names::Vector{Symbol}
    policies::Vector{PreparedPolicyData}
end

struct PreparedNodeData
    node_index::Int
    bindings::Vector{PreparedBindingData}
    input_names::Vector{String}
    positional_scratch::Vector{Any}
    keyword_scratch::Vector{Pair{Symbol,Any}}
    tuple_scratch::Vector{Any}
    binding_results_scratch::Vector{Bool}
end

function Base.getproperty(state::InterpretedGraphState, name::Symbol)
    name === :__executed && return getfield(state, :executed)

    labels = getfield(state, :index_by_label)

    if haskey(labels, name)
        idx = labels[name]
        return getfield(state, :operations)[idx]
    end

    name_str = String(name)
    if endswith(name_str, TIME_FIELD_SUFFIX)
        base_name = Symbol(first(split(name_str, TIME_FIELD_SUFFIX; limit=2)))
        if haskey(labels, base_name)
            idx = labels[base_name]
            return getfield(state, :times)[idx]
        end
    end

    getfield(state, name)
end

function Base.setproperty!(state::InterpretedGraphState, name::Symbol, value)
    name === :__executed && return copyto!(getfield(state, :executed), value)

    labels = getfield(state, :index_by_label)

    if haskey(labels, name)
        idx = labels[name]
        getfield(state, :operations)[idx] = value
        return value
    end

    name_str = String(name)
    if endswith(name_str, TIME_FIELD_SUFFIX)
        base_name = Symbol(first(split(name_str, TIME_FIELD_SUFFIX; limit=2)))
        if haskey(labels, base_name)
            idx = labels[base_name]
            getfield(state, :times)[idx] = value
            return value
        end
    end

    setfield!(state, name, value)
end

function interpreted_states(::Type{TTime}, graph::StreamGraph) where {TTime}
    verify_graph_connectedness(graph)
    topological_sort!(graph)
    verify_bindings_topo_order(graph)

    operations = Any[node.operation for node in graph.nodes]
    times = fill(time_zero(TTime), length(graph.nodes))
    executed = falses(length(graph.nodes))
    labels = [node.field_name for node in graph.nodes]
    index_by_label = Dict(label => idx for (idx, label) in enumerate(labels))
    state = InterpretedGraphState{TTime}(operations, times, executed, labels, index_by_label)
    reset!(state)
    state
end

function reset!(state::InterpretedGraphState{TTime}) where {TTime}
    fill!(state.executed, false)
    fill!(state.times, time_zero(TTime))

    for op in state.operations
        reset!(op)
    end

    nothing
end

function info(state::InterpretedGraphState{TTime}) where {TTime}
    entries = OrderedDict{Symbol,Type}()
    entries[:__executed] = BitVector
    for (idx, label) in enumerate(state.labels)
        entries[label] = typeof(state.operations[idx])
        entries[Symbol(string(label, TIME_FIELD_SUFFIX))] = TTime
    end
    entries
end

@inline function _state_execution_flags(states::GraphState)
    getproperty(states, :__executed)
end

@inline function _set_executed!(states::GraphState, idx::Int)
    _state_execution_flags(states)[idx] = true
    nothing
end

@inline function _reset_executed!(states::GraphState)
    fill!(_state_execution_flags(states), false)
end

@inline function _node_time_field(node::StreamNode)
    Symbol(string(node.field_name, TIME_FIELD_SUFFIX))
end

@inline function _set_node_time!(states::GraphState, node::StreamNode, value)
    Base.setproperty!(states, _node_time_field(node), value)
end

@inline function _get_node_state(states::GraphState, node::StreamNode)
    getproperty(states, node.field_name)
end

@inline function _hasfield(obj, name::Symbol)
    hasfield(typeof(obj), name)
end

@inline function _store_source_value!(source_state, value)
    if _hasfield(source_state, :last_value)
        source_state.last_value[] = value
    end
    if _hasfield(source_state, :has_value)
        source_state.has_value = true
    end
end

@inline function _collect_binding_value(states::GraphState, field_name::Symbol)
    get_state(getproperty(states, field_name))
end

@inline function _combine_and(result::Union{Nothing,Bool}, value::Bool)
    return isnothing(result) ? value : (result && value)
end

function _resolve_policy_nodes(
    policy_nodes,
    binding_node_indices::Vector{Int},
    graph::StreamGraph,
)
    if policy_nodes === :any
        return :any, binding_node_indices
    elseif policy_nodes === :all
        return :all, binding_node_indices
    else
        indices = [get_node(graph, node_label).index for node_label in policy_nodes]
        return :all, indices
    end
end

function _policy_field_names(node_indices::Vector{Int}, graph::StreamGraph)
    [graph.nodes[idx].field_name for idx in node_indices]
end

function _prepare_policy_data(
    policy::CallPolicy,
    binding_node_indices::Vector{Int},
    graph::StreamGraph,
)
    if policy isa Always
        return PreparedPolicyData(:always, :none, Int[], Symbol[], 0)
    elseif policy isa Never
        return PreparedPolicyData(:never, :none, Int[], Symbol[], 0)
    elseif policy isa IfSource
        source_index = get_node(graph, policy.source_node).index
        return PreparedPolicyData(:ifsource, :none, Int[], Symbol[], source_index)
    elseif policy isa IfExecuted
        mode, node_indices = _resolve_policy_nodes(policy.nodes, binding_node_indices, graph)
        return PreparedPolicyData(:ifexecuted, mode, node_indices, Symbol[], 0)
    elseif policy isa IfValid
        mode, node_indices = _resolve_policy_nodes(policy.nodes, binding_node_indices, graph)
        field_names = _policy_field_names(node_indices, graph)
        return PreparedPolicyData(:ifvalid, mode, node_indices, field_names, 0)
    elseif policy isa IfInvalid
        mode, node_indices = _resolve_policy_nodes(policy.nodes, binding_node_indices, graph)
        field_names = _policy_field_names(node_indices, graph)
        return PreparedPolicyData(:ifinvalid, mode, node_indices, field_names, 0)
    else
        error("Unknown call policy: $(typeof(policy))")
    end
end

function _prepare_binding_data(binding::InputBinding{StreamNode}, graph::StreamGraph)
    input_indices = [node.index for node in binding.input_nodes]
    input_field_names = [node.field_name for node in binding.input_nodes]
    policies = PreparedPolicyData[
        _prepare_policy_data(policy, input_indices, graph) for policy in binding.call_policies
    ]
    PreparedBindingData(binding.bind_as, input_indices, input_field_names, policies)
end

function _prepared_input_names(bindings::Vector{PreparedBindingData})
    names = String[]
    for binding in bindings
        append!(names, String.(binding.input_field_names))
    end
    names
end

function _prepare_node_data(node::StreamNode, graph::StreamGraph)
    bindings = PreparedBindingData[
        _prepare_binding_data(binding, graph) for binding in node.input_bindings
    ]

    input_names = _prepared_input_names(bindings)

    positional_capacity = 0
    keyword_capacity = 0
    tuple_capacity = 0
    for binding in bindings
        bind_as = binding.bind_as
        inputs_count = length(binding.input_field_names)
        if bind_as isa PositionParams
            positional_capacity += inputs_count
        elseif bind_as isa NamedParams
            keyword_capacity += inputs_count
        elseif bind_as isa TupleParams
            tuple_capacity = max(tuple_capacity, inputs_count)
            positional_capacity += 1
        end
    end

    positional_scratch = Any[]
    keyword_scratch = Pair{Symbol,Any}[]
    tuple_scratch = Any[]
    binding_results_scratch = Bool[]

    positional_capacity > 0 && sizehint!(positional_scratch, positional_capacity)
    keyword_capacity > 0 && sizehint!(keyword_scratch, keyword_capacity)
    tuple_capacity > 0 && sizehint!(tuple_scratch, tuple_capacity)
    sizehint!(binding_results_scratch, max(length(bindings), 1))

    PreparedNodeData(
        node.index,
        bindings,
        input_names,
        positional_scratch,
        keyword_scratch,
        tuple_scratch,
        binding_results_scratch,
    )
end

function _evaluate_binding(
    binding::PreparedBindingData,
    states::GraphState,
    executed_flags::BitVector,
    source_index::Int,
)
    has_active = false
    accumulator = nothing

    for policy in binding.policies
        if policy.kind === :always
            has_active = true
            continue
        elseif policy.kind === :never
            return false, has_active, true
        elseif policy.kind === :ifsource
            source_index == policy.source_index || return false, has_active, false
            has_active = true
        elseif policy.kind === :ifexecuted
            has_active = true
            value = if policy.mode === :any
                any(executed_flags[idx] for idx in policy.node_indices)
            else
                all(executed_flags[idx] for idx in policy.node_indices)
            end
            accumulator = _combine_and(accumulator, value)
        elseif policy.kind === :ifvalid
            has_active = true
            value = if policy.mode === :any
                any(is_valid(getproperty(states, field)) for field in policy.field_names)
            else
                all(is_valid(getproperty(states, field)) for field in policy.field_names)
            end
            accumulator = _combine_and(accumulator, value)
        elseif policy.kind === :ifinvalid
            has_active = true
            value = if policy.mode === :any
                any(!is_valid(getproperty(states, field)) for field in policy.field_names)
            else
                all(!is_valid(getproperty(states, field)) for field in policy.field_names)
            end
            accumulator = _combine_and(accumulator, value)
        else
            error("Unknown call policy for node binding: $(policy.kind)")
        end
    end

    if has_active
        return isnothing(accumulator) ? nothing : accumulator, true, true
    else
        return false, false, true
    end
end

function _prepare_call_arguments!(
    prepared_node::PreparedNodeData,
    states::GraphState,
    graph::StreamGraph,
)
    node = graph.nodes[prepared_node.node_index]
    positional = prepared_node.positional_scratch
    keyword_pairs = prepared_node.keyword_scratch
    tuple_scratch = prepared_node.tuple_scratch

    empty!(positional)
    empty!(keyword_pairs)

    for binding in prepared_node.bindings
        bind_mode = binding.bind_as
        if bind_mode isa PositionParams
            for field_name in binding.input_field_names
                push!(positional, _collect_binding_value(states, field_name))
            end
        elseif bind_mode isa NamedParams
            for field_name in binding.input_field_names
                push!(keyword_pairs, field_name => _collect_binding_value(states, field_name))
            end
        elseif bind_mode isa TupleParams
            empty!(tuple_scratch)
            for field_name in binding.input_field_names
                push!(tuple_scratch, _collect_binding_value(states, field_name))
            end
            push!(positional, tuple(tuple_scratch...))
        elseif bind_mode isa NoBind
            continue
        else
            error(
                "Unsupported parameter binding for node [$(label(node))]: $(typeof(bind_mode))",
            )
        end
    end

    positional, keyword_pairs
end

function _execute_functor(
    op_state,
    executor::GraphExecutor,
    positional::Vector{Any},
    keyword_pairs::Vector{Pair{Symbol,Any}},
)
    if isempty(keyword_pairs)
        op_state(executor, positional...)
    else
        op_state(executor, positional...; keyword_pairs...)
    end
end

function _execute_func_operation(
    op_state::Func,
    executor::GraphExecutor,
    positional::Vector{Any},
    keyword_pairs::Vector{Pair{Symbol,Any}},
)
    if isempty(keyword_pairs)
        value = op_state.func(executor, positional...)
    else
        value = op_state.func(executor, positional...; keyword_pairs...)
    end

    if has_output(op_state)
        op_state.last_value = value
    end

    nothing
end

function _execute_node!(
    executor::GraphExecutor,
    source_index::Int,
    prepared_node::PreparedNodeData,
    states::GraphState,
    graph::StreamGraph,
    debug::Bool,
)
    node = graph.nodes[prepared_node.node_index]
    executed_flags = _state_execution_flags(states)

    has_active = false
    binding_results = prepared_node.binding_results_scratch
    empty!(binding_results)

    for binding in prepared_node.bindings
        binding_eval, binding_active, continue_node =
            _evaluate_binding(binding, states, executed_flags, source_index)

        continue_node || return

        if binding_active
            has_active = true
            if binding_eval isa Bool
                push!(binding_results, binding_eval)
            end
        end
    end

    has_active || return

    do_execute = isempty(binding_results) ? true : any(binding_results)
    do_execute || return

    _set_node_time!(states, node, time(executor))
    _set_executed!(states, node.index)

    positional, keyword_pairs = _prepare_call_arguments!(prepared_node, states, graph)
    op_state = _get_node_state(states, node)

    if debug
        input_names = prepared_node.input_names
        try
            if op_state isa Func
                _execute_func_operation(op_state, executor, positional, keyword_pairs)
            else
                _execute_functor(op_state, executor, positional, keyword_pairs)
            end
        catch e
            message = "Execution of node [$(label(node))] with inputs [$(join(input_names, ","))] at time $(time(executor)) failed."
            throw(StreamOpsError(label(node), message, e))
        end
    else
        if op_state isa Func
            _execute_func_operation(op_state, executor, positional, keyword_pairs)
        else
            _execute_functor(op_state, executor, positional, keyword_pairs)
        end
    end

    nothing
end

function _time_sync_nodes(graph::StreamGraph)
    filter(node -> OperationTimeSync(node.operation), graph.nodes)
end

function build_interpreted_source!(
    executor::GraphExecutor,
    graph::StreamGraph,
    source_node::StreamNode;
    debug::Bool=false,
)
    downstream_indices = get_source_subgraph(graph, source_node)[2:end]
    prepared_nodes = PreparedNodeData[
        _prepare_node_data(graph.nodes[idx], graph) for idx in downstream_indices
    ]
    sync_nodes = _time_sync_nodes(graph)
    source_index = source_node.index

    function (exec::GraphExecutor, event_value)
        states = exec.states

        _reset_executed!(states)

        source_state = _get_node_state(states, source_node)
        _store_source_value!(source_state, event_value)
        _set_executed!(states, source_node.index)

        for prepared_node in prepared_nodes
            _execute_node!(exec, source_index, prepared_node, states, graph, debug)
        end

        current_time = time(exec)
        for node in sync_nodes
            update_time!(_get_node_state(states, node), current_time)
        end

        nothing
    end
end

@inline is_interpreted_state(::GraphState) = false
@inline is_interpreted_state(::InterpretedGraphState) = true

export interpreted_states, is_interpreted_state
