import ShowGraphviz


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
        return "$(node.label)<FONT POINT-SIZE=\"5\"> </FONT><SUP><FONT COLOR=\"gray\" POINT-SIZE=\"$(ceil(Int, 0.7nodefontsize))\">[$(node.index)]</FONT></SUP>"
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
                    println(io, "  node$(input_node.index) -> node$(node.index) [label=<Never> $headlabel color=gray style=dotted arrowhead=open penwidth=1 arrowsize=0.75 labeldistance=1.5];")
                else
                    label = join(graphviz_label.(input_binding.call_policies), "</TD></TR><TR><TD ALIGN=\"LEFT\">")
                    println(io, "  node$(input_node.index) -> node$(node.index) [label=<
                        <TABLE BORDER=\"0\" CELLBORDER=\"0\" CELLSPACING=\"0\" CELLPADDING=\"0\">
                            <TR><TD ALIGN=\"LEFT\">$label</TD></TR>
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
