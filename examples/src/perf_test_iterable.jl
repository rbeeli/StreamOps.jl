using Dates
using Timestamps64
using StreamOps
using InteractiveUtils

# provide overloads for custom time type `Timestamp64`
StreamOps.time_now(::Type{Timestamp64}) = now(Timestamp64)
StreamOps.time_zero(::Type{Timestamp64}) = Timestamp64(0)

function run()
    values_iter = ((Timestamp64(i), i) for i in 1:10_000_000)

    g = StreamGraph()

    source!(g, :values, HistoricIterable(Timestamp64, Int, values_iter))
    # buffer = sink!(g, :buffer, Buffer{Int}())

    # bind!(g, values, buffer)

    states = compile_graph!(Timestamp64, g)
    exe = HistoricExecutor{Timestamp64}(g, states)
    setup!(exe)

    Base.invokelatest() do
        adapter = exe.source_adapters[1]

        # display(@code_native advance!(adapter, exe))

        for _ in 1:10_000_000
            advance!(adapter, exe)
        end
    end

    nothing
end

# @time run()

# using ProfileView
# ProfileView.@profview run()

# VSCodeServer.@profview run()

using Profile, PProf
@profile run();
pprof(webport=58699)
