using Dates
using Timestamps64
using StreamOps

# provide overloads for custom time type `Timestamp64`
StreamOps.time_now(::Type{Timestamp64}) = now(Timestamp64)
StreamOps.time_zero(::Type{Timestamp64}) = Timestamp64(0)

function run()
    dts = Timestamp64[]
    counts = Float32[]
    wnd = Nanosecond(100)

    g = StreamGraph()
    values = source!(g, :values, out=Timestamp64, init=Timestamp64(0))
    rolling = op!(g, :rolling, TimeBuffer{Timestamp64,Timestamp64}(wnd, :closed), out=AbstractVector{Timestamp64})
    dts_node = op!(g, :dts_node, Func((exe, x) -> time(exe), Timestamp64(0)), out=Timestamp64)
    counts_node = op!(g, :counts_node, Func((exe, x) -> Float32(length(x)), 0f32), out=Float32)
    sink_dts = sink!(g, :sink_dts, Buffer(dts))
    sink_counts = sink!(g, :sink_counts, Buffer(counts))
    
    # Create edges between nodes (define the computation graph)
    bind!(g, values, rolling)
    bind!(g, rolling, dts_node)
    bind!(g, rolling, counts_node)
    bind!(g, dts_node, sink_dts)
    bind!(g, counts_node, sink_counts)
    
    # Compile the graph with historic executor
    exe = compile_historic_executor(Timestamp64, g, debug=!true)

    # Run simulation
    dts = [Timestamp64(i) for i in 1:10_000_000]
    start = first(dts)
    stop = last(dts)
    adapters = [
        IterableAdapter(exe, values, [
            (x, x) for x in dts
        ])
    ]
    run_simulation!(exe, adapters, start, stop)
       
    nothing
end

@time run()

# using ProfileView
# ProfileView.@profview run()
# VSCodeServer.@profview run()
