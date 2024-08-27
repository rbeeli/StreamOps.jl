"""
This example demonstrates how to use the StreamOps.jl library to create a simple
realtime computation graph with a timer source and a sink node that prints the
current time every second.

What's special about this example is that it uses the `Timestamps64` time type
instead of Julia's `DateTime` type.
""";

using StreamOps
using Dates
using Timestamps64

println("Number of Julia threads: $(Threads.nthreads())")

# provide overloads for custom time type `Timestamp64`
StreamOps.time_now(::Type{Timestamp64}) = now(Timestamp64)
StreamOps.time_zero(::Type{Timestamp64}) = Timestamp64(0)

g = StreamGraph()

# Create source nodes
timer = source!(g, :timer, out=Timestamp64, init=Timestamp64(0))

# Create sink node
output = sink!(g, :output, Func((exe, x) -> begin
    println("output at time $(time(exe)): $x")
end))

# Create edges between nodes (define the computation graph)
bind!(g, timer, output)

# Compile the graph with realtime executor
exe = compile_realtime_executor(Timestamp64, g, debug=!true)

# Run in realtime mode
start = round_origin(now(Timestamp64), Dates.Second(1), RoundUp)
stop = start + Dates.Second(5)
adapters = [
    RealTimerAdapter(exe, timer, interval=Dates.Millisecond(1000), start_time=start),
]
@time run_realtime!(exe, adapters, start_time=start, end_time=stop)
