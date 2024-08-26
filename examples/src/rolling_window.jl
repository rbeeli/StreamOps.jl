using StreamOps
using Dates

g = StreamGraph()

values = source!(g, :values, out=Float64, init=0.0)
rolling = op!(g, :rolling, WindowBuffer{Float64}(3), out=AbstractVector{Float64})
output = sink!(g, :output, Func((exe, x) -> println("output at time $(time(exe)): $x")))

# Create edges between nodes (define the computation graph)
bind!(g, values, rolling)
bind!(g, rolling, output)

exe = compile_historic_executor(DateTime, g, debug=!true)

start = DateTime(2000, 1, 1)
stop = DateTime(2000, 1, 10)
adapters = [
    IterableAdapter(exe, values, [
        (DateTime(2000, 1, 1), 1.0),
        (DateTime(2000, 1, 2), 2.0),
        (DateTime(2000, 1, 3), 2.5),
        (DateTime(2000, 1, 4), 1.75),
        (DateTime(2000, 1, 5), 2.1),
        (DateTime(2000, 1, 6), 3.0),
        (DateTime(2000, 1, 7), 4.0),
    ])
]
@time run_simulation!(exe, adapters, start_time=start, end_time=stop)
graphviz(exe.graph)