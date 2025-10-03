"""
Very basic example using `DateTime` as time type
and no computation nodes, only source and sink nodes.
""";

using StreamOps
using Dates

g = StreamGraph()

values_data = [
    (DateTime(2000, 1, 1), 1.0), #
    (DateTime(2000, 1, 2), 2.0),
]

source!(g, :values, HistoricIterable(Float64, values_data))
op!(g, :times_2, Func{Float64}((exe, x) -> 2x, NaN))
sink!(g, :output, Print())

# Create edges between nodes (define the computation graph)
bind!(g, :values, :times_2)
bind!(g, :times_2, :output)

# Compile the graph with historical executor
states = compile_graph!(DateTime, g)
exe = HistoricExecutor{DateTime}(g, states)
setup!(exe)

# Run simulation
start = DateTime(2000, 1, 1)
stop = DateTime(2000, 1, 10)
@time run!(exe, start, stop)

# Visualize the computation graph
graphviz(exe.graph)
