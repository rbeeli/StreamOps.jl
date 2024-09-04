"""
This example demonstrates the visualization capabilities of the StreamOps.jl library
on a more complex computation graph with multiple sources, compute nodes, and sinks.
""";

using StreamOps
using Dates

g = StreamGraph()

# Create source nodes
source1 = source!(g, :source1, out=Float64, init=NaN)
source2 = source!(g, :source2, out=Float64, init=NaN)
source3 = source!(g, :source3, out=Float64, init=NaN)

# Create compute nodes
square = op!(g, :square, Func{Float64}((exe, x) -> x^2, 0.0); out=Float64)
divide_by_2 = op!(g, :divide_by_2, Func{Float64}((exe, x) -> x / 2, 0.0); out=Float64)
negate = op!(g, :negate, Func{Float64}((exe, x) -> -x, 0.0); out=Float64)
combine = op!(g, :combine, Func{Tuple{Float64,Float64}}((exe, x, y) -> (x, y), (0.0, 0.0)); out=Tuple{Float64,Float64})
final_multiply = op!(g, :final_multiply, Func{Tuple{Float64,Float64}}((exe, tuple, src2, src3) -> tuple .* src2 .+ src3, (0.0, 0.0)); out=Tuple{Float64,Float64})

# Create sink nodes
output1 = sink!(g, :output1, Func((exe, x) -> println("output #1 at time $(time(exe)): $x"), nothing))
output2 = sink!(g, :output2, Func((exe, x) -> println("output #2 at time $(time(exe)): $x"), nothing))

# Create edges between nodes (define the computation graph)
bind!(g, source1, square)
bind!(g, square, divide_by_2)
bind!(g, source2, negate)
bind!(g, (divide_by_2, negate), combine)
bind!(g, (combine, source2, source3), final_multiply)
bind!(g, final_multiply, output1)
bind!(g, combine, output2)

# Compile the graph with historic executor
exe = compile_historic_executor(DateTime, g, debug=!true)

# Run simulation
adapters = [
    IterableAdapter(exe, source1, [
        (DateTime(2000, 1, 1, 0, 0, 1), 2.0),
        (DateTime(2000, 1, 1, 0, 0, 3), 4.0),
        (DateTime(2000, 1, 1, 0, 0, 5), 6.0)
    ]),
    IterableAdapter(exe, source2, [
        (DateTime(2000, 1, 1, 0, 0, 2), 10.0),
        (DateTime(2000, 1, 1, 0, 0, 4), 20.0),
        (DateTime(2000, 1, 1, 0, 0, 6), 30.0)
    ]),
    IterableAdapter(exe, source3, [
        (DateTime(2000, 1, 1, 0, 0, 2), 10.0),
        (DateTime(2000, 1, 1, 0, 0, 4), 20.0),
        (DateTime(2000, 1, 1, 0, 0, 6), 30.0)
    ])
]
run_simulation!(
    exe,
    adapters,
    DateTime(2000, 1, 1, 0, 0, 1),
    DateTime(2000, 1, 1, 0, 0, 6))

# Visualize the computation graph
graphviz(exe.graph)
