"""
Very basic example using custom `Timestamp64` as time type
and no computation nodes, only source and sink nodes.
""";

using StreamOps
using Dates
using Timestamps64

# provide overloads for custom time type `Timestamp64`
StreamOps.time_now(::Type{Timestamp64}) = now(Timestamp64)
StreamOps.time_zero(::Type{Timestamp64}) = Timestamp64(0)

function run()
    g = StreamGraph()

    source!(g, :values, out=Float64, init=0.0)
    sink!(g, :output, Print((exe, x) -> println("Output at $(time(exe)): $x")))

    # Create edges between nodes (define the computation graph)
    bind!(g, :values, :output)

    # Compile the graph with historic executor
    exe = compile_historic_executor(Timestamp64, g, debug=!true)

    # Run simulation
    start = Timestamp64(2000, 1, 1)
    stop = Timestamp64(2000, 1, 10)
    set_adapters!(exe, [
        HistoricIterable(exe, g[:values], [
            (Timestamp64(2000, 1, 1), 1.0),
            (Timestamp64(2000, 1, 2), 2.0),
        ])
    ])
    @time run_simulation!(exe, start, stop)
end

run()
