"""
Very basic example using `DateTime` as time type
and no computation nodes, only source and sink nodes.
""";

using StreamOps
using Dates

g = StreamGraph()

source!(g, :values, out=Float64, init=0.0)
sink!(g, :output, Print())

# Create edges between nodes (define the computation graph)
bind!(g, :values, :output)

# Compile the graph with historic executor
states = compile_graph!(DateTime, g)
exe = HistoricExecutor{DateTime}(g, states)
setup!(exe)

# Run simulation
start = DateTime(2000, 1, 1)
stop = DateTime(2000, 1, 10)
set_adapters!(exe, [
    HistoricIterable(exe, g[:values], [
        (DateTime(2000, 1, 1), 1.0),
        (DateTime(2000, 1, 2), 2.0),
    ])
])
@time run!(exe, start, stop)

# Visualize the computation graph
graphviz(exe.graph)
