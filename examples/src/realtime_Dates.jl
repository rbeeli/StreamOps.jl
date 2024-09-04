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
timer = source!(g, :timer, out=DateTime, init=DateTime(0))

# Create sink node
output = sink!(g, :output, Func((exe, x) -> begin
    println("output at time $(Dates.format(time(exe), "yyyy-mm-ddTHH:MM:SS.sss")): $x")
end, nothing))

# Create edges between nodes (define the computation graph)
bind!(g, timer, output)

# Compile the graph with realtime executor
exe = compile_realtime_executor(DateTime, g, debug=!true)

# Run in realtime mode
start = round_origin(now(UTC), Dates.Second(1), RoundUp)
stop = start + Dates.Second(5)
adapters = [
    RealTimerAdapter(exe, timer, interval=Dates.Millisecond(1000), start_time=start),
]
@time run_realtime!(exe, adapters, start_time=start, end_time=stop)
