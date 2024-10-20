"""
This example demonstrates how to view the internals of the StreamOps.jl library
for debugging and performance optimization purposes.

The Julia macros like `@code_warntype` etc. can be used to inspect the
generated graph computation and simulation code.
""";

using StreamOps
using Dates

g = StreamGraph()

# Create source nodes
source!(g, :source_timer, out=DateTime, init=DateTime(0))

# Create sink nodes
sink!(g, :output, Func((exe, x) -> println("output at time $(time(exe)): $x"), nothing))
sink!(g, :counter, Counter())

# Create edges between nodes (define the computation graph)
bind!(g, :source_timer, :output)
bind!(g, :source_timer, :counter)

# Compile the graph with historic executor
states = compile_graph!(DateTime, g, debug=true)
exe = HistoricExecutor{DateTime}(g, states)
setup!(exe, debug=true)

# Run simulation
start = DateTime(2000, 1, 1, 0, 0, 0)
stop = DateTime(2000, 1, 1, 0, 0, 59)

set_adapters!(exe, [
    HistoricTimer{DateTime}(exe, g[:source_timer], interval=Second(5), start_time=start),
])
@time run!(exe, start, stop)

println("Counter: ", get_state(g[:counter].operation))

# Visualize the computation graph
graphviz(exe.graph)

# View compiled states struct of graph
StreamOps.info(exe.states)

# Dump the states struct to console
dump(exe.states)

# Inspect code of simulation loop
@code_warntype run!(exe, start, stop)

# Inspect code for executing a source adapter
@code_warntype advance!(exe.adapters[1], exe)

# Inspect generated computation graph code of the source node (adapter).
# This is where the actual computation of nodes happens and the graph is traversed.
# For best performance, this code should be type-stable and
# allocations should be minimized.
@code_warntype exe.adapters[1].adapter_func(exe, exe.adapters[1].current_time)

@code_native exe.adapters[1].adapter_func(exe, exe.adapters[1].current_time)
