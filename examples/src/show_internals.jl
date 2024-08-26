using StreamOps
using Dates

g = StreamGraph()

# Create source nodes
source_timer = source!(g, :source_timer, out=DateTime, init=DateTime(0))

# Create sink nodes
output = sink!(g, :output, Func((exe, x) -> println("output at time $(time(exe)): $x")))
counter = sink!(g, :counter, Counter())

# Create edges between nodes (define the computation graph)
bind!(g, source_timer, output)
bind!(g, source_timer, counter)

exe = compile_historic_executor(DateTime, g, debug=!true)

start = DateTime(2000, 1, 1, 0, 0, 0)
stop = DateTime(2000, 1, 1, 0, 0, 59)

adapters = [
    TimerAdapter{DateTime}(exe, source_timer, interval=Dates.Second(5), start_time=start),
]
@time run_simulation!(exe, adapters, start, stop)

println("Counter: ", get_state(counter.operation))

# Visualize the computation graph
graphviz(exe.graph)

# View compiled states struct of graph
StreamOps.info(exe.states)

# Dump the states struct to console
dump(exe.states)

# @code_warntype run_simulation!(exe, adapters, start, stop)

@code_warntype run_simulation!(exe, adapters, start, stop)

# Inspect code for executing an adapter
@code_warntype advance!(adapters[1], exe)

# Inspect generated computation graph code.
# This is where the actual computation of nodes happens and the graph is traversed.
# For best performance, this code should be type-stable.
@code_warntype adapters[1].adapter_func(exe, adapters[1].current_time)
