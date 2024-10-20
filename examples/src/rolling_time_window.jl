"""
This example demonstrates how to capture a rolling window of values
using a `TimeWindowBuffer` node, which maintains a buffer of values within a time window
instead of a fixed number of values.
""";

using StreamOps
using Dates

g = StreamGraph()

source!(g, :values, out=Float64, init=0.0)
op!(g, :rolling, TimeWindowBuffer{DateTime,Float64}(Day(3), :closed), out=AbstractVector{Float64})
sink!(g, :output, Func((exe, x) -> println("output at time $(time(exe)): $x"), nothing))

# Create edges between nodes (define the computation graph)
bind!(g, :values, :rolling)
bind!(g, :rolling, :output)

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
        (DateTime(2000, 1, 3), 2.5),
        (DateTime(2000, 1, 4), 1.75),
        (DateTime(2000, 1, 5), 2.1),
        (DateTime(2000, 1, 6), 3.0),
        (DateTime(2000, 1, 10), 4.0),
    ])
])
@time run!(exe, start, stop)

# Visualize the computation graph
graphviz(exe.graph)
