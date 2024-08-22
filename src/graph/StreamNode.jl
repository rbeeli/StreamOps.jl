"""
A node in a stream computation graph that represents a computation step.

Types of nodes:
- **Source**: The node has no incoming edges, emits data.
- **Sink**: The node has no outgoing edges, consumes/stores data.
- **Operation**: The node has both incoming and outgoing edges, and performs a computation step.
    - **Stateful**: The node has an internal state that is updated during computation.
    - **Stateless**: The node has no internal state, and the output is a function of the input only.
"""
mutable struct StreamNode
    index::Int
    is_source::Bool
    operation::StreamOperation
    input_bindings::Vector{InputBinding{StreamNode}}
    binding_mode::ParamsBinding
    output_type::Type
    label::Symbol
    field_name::Symbol
    function StreamNode(index, is_source, operation::StreamOperation, binding_mode, output_type, label::Symbol)
        input_bindings = InputBinding{StreamNode}[]
        field_name = label
        new(index, is_source, operation, input_bindings, binding_mode, output_type, label, field_name)
    end
end

@inline is_source(node::StreamNode) = node.is_source

@inline is_sink(node::StreamNode) = node.output_type == Nothing

@inline label(node::StreamNode) = node.label
