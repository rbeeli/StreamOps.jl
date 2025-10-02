using Dates
using Timestamps64
using StreamOps

# provide overloads for custom time type `Timestamp64`
StreamOps.time_now(::Type{Timestamp64}) = now(Timestamp64)
StreamOps.time_zero(::Type{Timestamp64}) = Timestamp64(0)

function run()
    dts_buffer = Timestamp64[]
    counts = Float32[]
    wnd = Nanosecond(100)

    data_points = [Timestamp64(i) for i in 1:20_000_000]
    values_iter = ((x, x) for x in data_points)

    g = StreamGraph()
    source!(g, :values, HistoricIterable(Timestamp64, values_iter))
    op!(g, :rolling, TimeWindowBuffer{Timestamp64,Timestamp64}(wnd, :closed), out=AbstractVector{Timestamp64})
    op!(g, :dts_node, Func((exe, x) -> time(exe), Timestamp64(0)), out=Timestamp64)
    op!(g, :counts_node, Func((exe, x) -> Float32(length(x)), 0.0f32), out=Float32)
    sink!(g, :sink_dts, Buffer(dts_buffer))
    sink!(g, :sink_counts, Buffer(counts))

    # Create edges between nodes (define the computation graph)
    bind!(g, :values, :rolling)
    bind!(g, :rolling, :dts_node)
    bind!(g, :rolling, :counts_node)
    bind!(g, :dts_node, :sink_dts)
    bind!(g, :counts_node, :sink_counts)

    # Compile the graph with historical executor
    states = compile_graph!(Timestamp64, g)
    exe = HistoricExecutor{Timestamp64}(g, states)
    setup!(exe)

    # Run simulation
    start = first(data_points)
    stop = last(data_points)
    run!(exe, start, stop)

    nothing
end

# @time run()

using ProfileView
ProfileView.@profview run()
# VSCodeServer.@profview run()
