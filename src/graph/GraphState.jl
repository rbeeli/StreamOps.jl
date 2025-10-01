using DataStructures: OrderedDict

"""
Returns whether the given node has been executed
for the current adapter (source) call.
With each adapter call, the executed state of all nodes is reset to false.
"""
function did_execute(states::T, node::StreamNode) where {T<:GraphState}
    @inbounds states.__executed[node.index]
end

"""
Returns the field names and types of the given states struct.
"""
function info(states::T) where {T<:GraphState}
    type = typeof(states)
    OrderedDict(zip(fieldnames(type), fieldtypes(type)))
end

"""
Compile the states struct for the given graph to store intermediate results
of computation steps.
"""
function compile_states_struct(::Type{TTime}, graph::StreamGraph; debug::Bool=false) where {TTime}
    # Generate a unique name for the struct
    struct_name = Symbol("GraphState_$(time_ns())")

    field_defs = []
    ctor_args = []

    push!(field_defs, :(__executed::BitVector))
    push!(ctor_args, :(falses($(length(graph.nodes)))))

    for (i, node) in enumerate(graph.nodes)
        # state value field
        field_type = typeof(node.operation)
        push!(field_defs, Expr(:(::), node.field_name, field_type))
        push!(ctor_args, node.operation)

        # state time field
        push!(field_defs, Expr(:(::), Symbol("$(node.field_name)__time"), TTime))
        push!(ctor_args, :(StreamOps.time_zero($TTime)))
    end

    struct_def = Expr(
        :struct, true, :($(struct_name) <: StreamOps.GraphState), Expr(:block, field_defs...)
    )
    eval(struct_def)

    ctor_def = :($struct_name() = $struct_name($(ctor_args...)))
    eval(ctor_def)

    debug && println("Generated states struct:")
    debug && println(struct_def)

    eval(struct_name)
end

function compile_reset_method!(
    ::Type{TTime}, states_type::Type{<:GraphState}, graph::StreamGraph; debug::Bool=false
) where {TTime}
    body_exprs = Expr[]
    push!(body_exprs, :(fill!(states.__executed, false)))

    for node in graph.nodes
        field_name = node.field_name
        time_field = Symbol("$(field_name)__time")
        push!(body_exprs, :(states.$time_field = StreamOps.time_zero($TTime)))
        push!(body_exprs, :(reset!(states.$field_name)))
    end

    func_expr = quote
        function StreamOps.reset!(states::$states_type)
            $(body_exprs...)
            nothing
        end
    end

    eval(func_expr)

    if debug
        println("Generated reset! method:")
        StreamOps._print_expression(func_expr)
    end

    nothing
end

export did_execute, info, compile_states_struct
