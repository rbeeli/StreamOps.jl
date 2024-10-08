"""
This example demonstrates how to combine values from multiple sources
and pass them to a single node, which in this example is a `Func` node
that creates a tuple of the values.
""";

using StreamOps
using Dates

g = StreamGraph()

# Create source nodes
values1 = source!(g, :values1, out=Float64, init=NaN)
values2 = source!(g, :values2, out=Float64, init=NaN)
values3 = source!(g, :values3, out=Float64, init=NaN)
values4 = source!(g, :values4, out=Float64, init=NaN)

# Create combine node
combine = op!(g, :combine, Func{NTuple{4,Any}}((exe, x1, x2, x3, x4) -> tuple(x1, x2, x3, x4), ntuple(x -> 0.0, 4)), out=NTuple{4,Any})

# Create sink node
output = sink!(g, :output, Func((exe, x) -> println("output at time $(time(exe)): $x"), nothing))

# Create edges between nodes (define the computation graph)
bind!(g, (values1, values2, values3, values4), combine)
bind!(g, combine, output)

# Compile the graph with historic executor
exe = compile_historic_executor(DateTime, g, debug=!true)

# Run simulation
start = DateTime(1999, 12, 31)
stop = DateTime(2000, 1, 10)
adapters = [
    IterableAdapter(exe, values1, [
        (DateTime(2000, 1, 1), 1.0),
        (DateTime(2000, 1, 2), 2.0),
        (DateTime(2000, 1, 3), 3.0),
        (DateTime(2000, 1, 4), 4.0),
        (DateTime(2000, 1, 5), 5.0),
        (DateTime(2000, 1, 6), 6.0),
        (DateTime(2000, 1, 7), 7.0),
    ]),
    IterableAdapter(exe, values2, [
        (DateTime(2000, 1, 2), 20.0),
        (DateTime(2000, 1, 4), 40.0),
        (DateTime(2000, 1, 6), 60.0),
        (DateTime(2000, 1, 8), 80.0),
    ]),
    IterableAdapter(exe, values3, [
        (DateTime(1999, 12, 31), 1000.0),
    ]),
    IterableAdapter(exe, values4, Float64[]) # empty
]
@time run_simulation!(exe, adapters, start, stop)

# Visualize the computation graph
graphviz(exe.graph)
