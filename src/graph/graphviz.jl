using ShowGraphviz: ShowGraphviz

function graphviz(
    graph::StreamGraph;
    nodefontsize=10,
    edgefontsize=8,
    nodefontname="Helvetica,Arial,sans-serif",
    edgefontname="Helvetica,Arial,sans-serif",
    layout="dot",
)
    io = IOBuffer()

    println(io, "digraph G {")
    println(io, "  layout=$layout")
    println(io, "  node [fontsize=$nodefontsize fontname=\"$nodefontname\"];")
    println(io, "  edge [fontsize=$edgefontsize fontname=\"$edgefontname\" fontcolor=\"#666666\"];")

    function html_escape(str::AbstractString)
        replaced = replace(str, '&' => "&amp;")
        replaced = replace(replaced, '<' => "&lt;")
        replace(replaced, '>' => "&gt;")
    end

    type_font_size = ceil(Int, 0.6nodefontsize)

    function make_label(node::StreamNode)
        base = "$(node.label)<FONT POINT-SIZE=\"5\"> </FONT><SUP><FONT COLOR=\"gray\" POINT-SIZE=\"$(ceil(Int, 0.7nodefontsize))\">[$(node.index)]</FONT></SUP>"
        type_str = sprint(show, node.output_type)
        return base * "<BR/><FONT COLOR=\"gray\" POINT-SIZE=\"$type_font_size\">::" * html_escape(type_str) * "</FONT>"
    end

    # Source nodes (at the top)
    println(io, "  { rank=source; ")
    for node in filter(is_source, graph.nodes)
        println(
            io,
            "    node$(node.index) [label=<$(make_label(node))> shape=rect color=blue penwidth=0.75 style=\"rounded\"];",
        )
    end
    println(io, "  }")

    # Computation nodes
    for node in graph.nodes
        if !is_source(node) && !is_sink(node)
            println(
                io,
                "  node$(node.index) [label=<$(make_label(node))> shape=rect color=black penwidth=0.75 style=\"rounded\"];",
            )
        end
    end

    # Sink nodes (at the bottom)
    println(io, "  { rank=sink; ")
    for node in filter(is_sink, graph.nodes)
        println(
            io,
            "    node$(node.index) [label=<$(make_label(node))> shape=rect color=green penwidth=1 style=\"rounded\"];",
        )
    end
    println(io, "  }")

    # Add edges to the graph
    for (i, node) in enumerate(graph.nodes)
        edge_counter = 1
        for input_binding in node.input_bindings
            for input_node in input_binding.input_nodes
                headlabel = if length(input_binding.input_nodes) > 1
                    "headlabel=<<FONT POINT-SIZE=\"$(ceil(Int, 0.6nodefontsize))\">$(edge_counter).</FONT>>"
                else
                    ""
                end

                # call_policies
                if first(input_binding.call_policies) isa Never
                    # input has no call policies, i.e. it does never trigger the node
                    println(
                        io,
                        "  node$(input_node.index) -> node$(node.index) [label=<Never> $headlabel color=gray style=dotted arrowhead=open penwidth=1 arrowsize=0.75 labeldistance=1.5];",
                    )
                else
                    label = join(
                        graphviz_label.(input_binding.call_policies),
                        "</TD></TR><TR><TD ALIGN=\"LEFT\">",
                    )
                    println(
                        io,
                        "  node$(input_node.index) -> node$(node.index) [label=<
                <TABLE BORDER=\"0\" CELLBORDER=\"0\" CELLSPACING=\"0\" CELLPADDING=\"0\">
                    <TR><TD ALIGN=\"LEFT\">$label</TD></TR>
                </TABLE>> arrowhead=open penwidth=0.5 arrowsize=0.75 labeldistance=1.5 $headlabel];",
                    )
                end

                edge_counter += 1
            end
        end
    end

    println(io, "}") # end digraph

    dot_code = String(take!(io))
    ShowGraphviz.DOT(dot_code)
end

export graphviz
