"""
This example demonstrates how to pass multiple bound input nodes
into a function via positional parameters, i.e. the order of the
parameters in the function signature must match the order of the
bound input nodes.
""";

using StreamOps
using Dates

g = StreamGraph()

# Create source nodes
start = DateTime(2000, 1, 1, 0, 0, 0)

values_data = [
    (DateTime(2000, 1, 1, 0, 0, 1), 1.0),
    (DateTime(2000, 1, 1, 0, 0, 2), 2.0),
    (DateTime(2000, 1, 1, 0, 0, 4), 4.0),
    (DateTime(2000, 1, 1, 0, 0, 7), 7.0),
    (DateTime(2000, 1, 1, 0, 0, 10), 10.0),
    (DateTime(2000, 1, 1, 0, 0, 15), 15.0),
    (DateTime(2000, 1, 1, 0, 0, 16), 16.0),
]

source!(g, :timer, HistoricTimer(interval=Second(5), start_time=start))
source!(g, :values, HistoricIterable(Float64, values_data))

# Create sink node with named parameters
func = Func((exe, timer, values) -> println("output at time $(time(exe)): timer=$timer values=$values"), nothing)
sink!(g, :output, func)

# Create edges between nodes (define the computation graph)
bind!(g, (:timer, :values), :output, bind_as=PositionParams())

# Compile the graph with historical executor
states = compile_graph!(DateTime, g)
exe = HistoricExecutor{DateTime}(g, states)
setup!(exe)

# Run simulation
stop = DateTime(2000, 1, 1, 0, 0, 59)
@time run!(exe, start, stop)

# Visualize the computation graph
graphviz(exe.graph)
