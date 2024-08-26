using StreamOps
using Dates

g = StreamGraph()

# Create source nodes
timer = source!(g, :timer, out=DateTime, init=DateTime(0))
values = source!(g, :values, out=Float64, init=0.0)

# Create sink node with named parameters
func = Func((exe, timer, values) -> println("output at time $(time(exe)): timer=$timer values=$values"))
output = sink!(g, :output, func, params_bind=PositionParams())

# Create edges between nodes (define the computation graph)
bind!(g, (timer, values), output)

exe = compile_historic_executor(DateTime, g, debug=!true)

start = DateTime(2000, 1, 1, 0, 0, 0)
stop = DateTime(2000, 1, 1, 0, 0, 59)
adapters = [
    TimerAdapter{DateTime}(exe, timer, interval=Dates.Second(5), start_time=start),
    IterableAdapter(exe, values, [
        (DateTime(2000, 1, 1, 0, 0, 1), 1.0),
        (DateTime(2000, 1, 1, 0, 0, 2), 2.0),
        (DateTime(2000, 1, 1, 0, 0, 4), 4.0),
        (DateTime(2000, 1, 1, 0, 0, 7), 7.0),
        (DateTime(2000, 1, 1, 0, 0, 10), 10.0),
        (DateTime(2000, 1, 1, 0, 0, 15), 15.0),
        (DateTime(2000, 1, 1, 0, 0, 16), 16.0),
    ]),
]
@time run_simulation!(exe, adapters, start, stop)
graphviz(exe.graph)
