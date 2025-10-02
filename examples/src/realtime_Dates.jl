"""
This example demonstrates how to use the StreamOps.jl library to create a simple
realtime computation graph with a timer source and a sink node that prints the
current time every second.
""";

using StreamOps
using Dates

println("Number of Julia threads: $(Threads.nthreads())")
if Threads.nthreads() == 1
    @warn "Julia is running in single-threaded mode. Console output might be delayed."
end

g = StreamGraph()

# Create source node
source!(g, :timer, RealtimeTimer(interval=Millisecond(1000), start_time=DateTime(0)))

# Create sink node
sink!(g, :output, Func((exe, x) -> begin
    println("output at time $(Dates.format(time(exe), "yyyy-mm-ddTHH:MM:SS.sss")): $x")
end, nothing))

# Create edges between nodes (define the computation graph)
bind!(g, :timer, :output)

# Compile the graph with realtime executor
states = compile_graph!(DateTime, g; debug=false)
exe = RealtimeExecutor{DateTime}(g, states)
setup!(exe)

# Run in realtime mode
start = round_origin(now(UTC), Second(1), RoundUp)
stop = start + Second(5)
@time run!(exe, start, stop)
