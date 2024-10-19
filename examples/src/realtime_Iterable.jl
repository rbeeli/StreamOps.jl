"""
This example demonstrates how to use the StreamOps.jl library to create a simple
realtime computation graph with a predefined iterable source where the values are emitted
as soon as their scheduled times are reached, and a sink node that prints the
current value received.

What's special about this example is that it uses the `Timestamps64` time type
instead of Julia's `DateTime` type.
""";

using StreamOps
using Dates
using Timestamps64

println("Number of Julia threads: $(Threads.nthreads())")
if Threads.nthreads() == 1
    @warn "Julia is running in single-threaded mode. Console output might be delayed."
end

# provide overloads for custom time type `Timestamp64`
StreamOps.time_now(::Type{Timestamp64}) = now(Timestamp64)
StreamOps.time_zero(::Type{Timestamp64}) = Timestamp64(0)

g = StreamGraph()

# Create source nodes
source!(g, :number, out=Float64, init=NaN)

# Create sink node
sink!(g, :output, Func((exe, x) -> begin
    println("output at time $(time(exe)): $x")
end, nothing))

# Create edges between nodes (define the computation graph)
bind!(g, :number, :output)

# Compile the graph with realtime executor
exe = compile_realtime_executor(Timestamp64, g, debug=!true)

# Run in realtime mode
start = round_origin(now(Timestamp64), Dates.Second(1), RoundUp)
stop = start + Dates.Second(5)
values = [
    (start + Second(1), 1.0),
    (start + Second(2), 2.0),
    (start + Second(3), 3.0),
    (start + Second(4), 4.0),
]
adapters = [
    RealtimeIterable(exe, g[:number], values)
]
@time run_realtime!(exe, adapters, start_time=start, end_time=stop)
