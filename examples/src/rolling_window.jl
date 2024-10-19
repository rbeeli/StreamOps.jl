"""
This example demonstrates how to capture a rolling window of values
using a `WindowBuffer` node.
The rolling window has a fixed window size.
""";

using StreamOps
using Dates

g = StreamGraph()

source!(g, :values, out=Float64, init=0.0)
op!(g, :rolling, WindowBuffer{Float64}(3), out=AbstractVector{Float64})
sink!(g, :output, Func((exe, x) -> println("output at time $(time(exe)): $x"), nothing))

# Create edges between nodes (define the computation graph)
bind!(g, :values, :rolling)
bind!(g, :rolling, :output)

# Compile the graph with historic executor
exe = compile_historic_executor(DateTime, g, debug=!true)

# Run simulation
start = DateTime(2000, 1, 1)
stop = DateTime(2000, 1, 10)
set_adapters!(exe,  [
    HistoricIterable(exe, g[:values], [
        (DateTime(2000, 1, 1), 1.0),
        (DateTime(2000, 1, 2), 2.0),
        (DateTime(2000, 1, 3), 2.5),
        (DateTime(2000, 1, 4), 1.75),
        (DateTime(2000, 1, 5), 2.1),
        (DateTime(2000, 1, 6), 3.0),
        (DateTime(2000, 1, 7), 4.0),
    ])
])
@time run!(exe, start, stop)

# Visualize the computation graph
graphviz(exe.graph)
