"""
This example demonstrates how to use the `Buffer` and `Func` nodes to create
a time-based buffer that flushes its contents at regular intervals.
The buffer is manually flushed by the `timer` source node every 5 seconds.
""";

using StreamOps
using Dates

g = StreamGraph()

# Create source nodes
source!(g, :timer, out=DateTime, init=DateTime(0))
source!(g, :values, out=Float64, init=0.0)

# Create operation nodes
op!(g, :buffer, Buffer{Float64}(), out=Buffer{Float64})
op!(g, :flush, Func{Vector{Float64}}((exe, dt, buf) -> begin
    vals = copy(buf)
    empty!(buf)
    vals
end, Float64[]), out=Vector{Float64})

# Create sink nodes
sink!(g, :output1, Func((exe, x) -> println("output at time $(time(exe)): $x"), nothing))

# Create edges between nodes (define the computation graph)
bind!(g, :values, :buffer)
bind!(g, (:timer, :buffer), :flush, call_policies=[IfExecuted(:timer)])
bind!(g, :flush, :output1)

# Compile the graph with historical executor
states = compile_graph!(DateTime, g)
exe = HistoricExecutor{DateTime}(g, states)
setup!(exe)

# Run simulation
start = DateTime(2000, 1, 1)
stop = DateTime(2000, 1, 6)
set_adapters!(exe, [
    HistoricTimer{DateTime}(exe, g[:timer], interval=Day(2), start_time=start),
    HistoricIterable(exe, g[:values], [
        (DateTime(2000, 1, 1, 0, 1, 1), 1.0),
        (DateTime(2000, 1, 1, 0, 1, 2), 1.5),
        (DateTime(2000, 1, 2, 0, 0, 0), 2.0),
        (DateTime(2000, 1, 2, 1, 0, 0), 2.1),
        (DateTime(2000, 1, 3, 0, 0, 1), 3.0),
        (DateTime(2000, 1, 4, 0, 0, 1), 4.0),
        (DateTime(2000, 1, 4, 1, 0, 1), 4.1),
        (DateTime(2000, 1, 5, 0, 0, 1), 5.0),
        (DateTime(2000, 1, 6, 0, 0, 0), 6.0)
    ])
])
@time run!(exe, start, stop)

# Visualize the computation graph
graphviz(exe.graph)
