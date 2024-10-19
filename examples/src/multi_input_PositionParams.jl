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
timer = source!(g, :timer, out=DateTime, init=DateTime(0))
values = source!(g, :values, out=Float64, init=0.0)

# Create sink node with named parameters
func = Func((exe, timer, values) -> println("output at time $(time(exe)): timer=$timer values=$values"), nothing)
output = sink!(g, :output, func)

# Create edges between nodes (define the computation graph)
bind!(g, (timer, values), output, bind_as=PositionParams())

# Compile the graph with historic executor
exe = compile_historic_executor(DateTime, g, debug=!true)

# Run simulation
start = DateTime(2000, 1, 1, 0, 0, 0)
stop = DateTime(2000, 1, 1, 0, 0, 59)
adapters = [
    HistoricTimer{DateTime}(exe, timer, interval=Dates.Second(5), start_time=start),
    HistoricIterable(exe, values, [
        (DateTime(2000, 1, 1, 0, 0, 1), 1.0),
        (DateTime(2000, 1, 1, 0, 0, 2), 2.0),
        (DateTime(2000, 1, 1, 0, 0, 4), 4.0),
        (DateTime(2000, 1, 1, 0, 0, 7), 7.0),
        (DateTime(2000, 1, 1, 0, 0, 10), 10.0),
        (DateTime(2000, 1, 1, 0, 0, 15), 15.0),
        (DateTime(2000, 1, 1, 0, 0, 16), 16.0),
    ]),
]
@time run_simulation!(exe, adapters, start, stop)

# Visualize the computation graph
graphviz(exe.graph)
