"""
This example demonstrates how to pass multiple bound input nodes
into a function as named parameters.
""";

using StreamOps
using Dates

g = StreamGraph()

# Create source nodes
source!(g, :timer, out=DateTime, init=DateTime(0))
source!(g, :values, out=Float64, init=0.0)

# Create sink node with named parameters
func = Func((exe; values, timer) -> println("output at time $(time(exe)): timer=$timer values=$values"), nothing)
sink!(g, :output, func)

# Create edges between nodes (define the computation graph)
bind!(g, (:timer, :values), :output, bind_as=NamedParams())

# Compile the graph with historic executor
exe = compile_historic_executor(DateTime, g, debug=!true)

# Run simulation
start = DateTime(2000, 1, 1, 0, 0, 0)
stop = DateTime(2000, 1, 1, 0, 0, 59)
set_adapters!(exe, [
    HistoricTimer{DateTime}(exe, g[:timer], interval=Second(5), start_time=start),
    HistoricIterable(exe, g[:values], [
        (DateTime(2000, 1, 1, 0, 0, 1), 1.0),
        (DateTime(2000, 1, 1, 0, 0, 2), 2.0),
        (DateTime(2000, 1, 1, 0, 0, 4), 4.0),
        (DateTime(2000, 1, 1, 0, 0, 7), 7.0),
        (DateTime(2000, 1, 1, 0, 0, 10), 10.0),
        (DateTime(2000, 1, 1, 0, 0, 15), 15.0),
        (DateTime(2000, 1, 1, 0, 0, 16), 16.0),
    ]),
])
@time run!(exe, start, stop)

# Visualize the computation graph
graphviz(exe.graph)
