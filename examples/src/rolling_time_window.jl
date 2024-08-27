"""
This example demonstrates how to capture a rolling window of values
using a `TimeBuffer` node, which maintains a buffer of values within a time window
instead of a fixed number of values.
""";

using StreamOps
using Dates

g = StreamGraph()

values = source!(g, :values, out=Float64, init=0.0)
rolling = op!(g, :rolling, TimeBuffer{DateTime,Float64}(Day(3), :closed), out=AbstractVector{Float64})
output = sink!(g, :output, Func((exe, x) -> println("output at time $(time(exe)): $x")))

# Create edges between nodes (define the computation graph)
bind!(g, values, rolling)
bind!(g, rolling, output)

# Compile the graph with historic executor
exe = compile_historic_executor(DateTime, g, debug=!true)

# Run simulation
start = DateTime(2000, 1, 1)
stop = DateTime(2000, 1, 10)
adapters = [
    IterableAdapter(exe, values, [
        (DateTime(2000, 1, 1), 1.0),
        (DateTime(2000, 1, 3), 2.5),
        (DateTime(2000, 1, 4), 1.75),
        (DateTime(2000, 1, 5), 2.1),
        (DateTime(2000, 1, 6), 3.0),
        (DateTime(2000, 1, 10), 4.0),
    ])
]
@time run_simulation!(exe, adapters, start, stop)

# Visualize the computation graph
graphviz(exe.graph)
