using StreamOps
using Dates

g = StreamGraph()

# Create source nodes
timer = source!(g, :timer, out=DateTime, init=DateTime(0))
values = source!(g, :values, out=Float64, init=0.0)

# Create operation nodes
buffer = op!(g, :buffer, Buffer{Float64}(), out=Buffer{Float64})
flush_buffer = op!(g, :flush_buffer, Func{Vector{Float64}}((exe, buf, dt) -> begin
    vals = copy(buf)
    empty!(buf)
    vals
end, Float64[]), out=Vector{Float64})

# Create sink nodes
output1 = sink!(g, :output1, Func((exe, x) -> println("output at time $(time(exe)): $x")))

# Create edges between nodes (define the computation graph)
bind!(g, values, buffer)
bind!(g, buffer, flush_buffer, call_policies=[Never()])
bind!(g, timer, flush_buffer)
bind!(g, flush_buffer, output1)

exe = compile_historic_executor(DateTime, g, debug=!true)

start = DateTime(2000, 1, 1)
stop = DateTime(2000, 1, 6)
adapters = [
    TimerAdapter{DateTime}(exe, timer, interval=Dates.Day(2), start_time=start),
    IterableAdapter(exe, values, [
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
]
@time run_simulation!(exe, adapters, start_time=start, end_time=stop)
graphviz(exe.graph)