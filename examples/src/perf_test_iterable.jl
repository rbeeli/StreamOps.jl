using Dates
using Timestamps64
using StreamOps
using InteractiveUtils

# provide overloads for custom time type `Timestamp64`
StreamOps.time_now(::Type{Timestamp64}) = now(Timestamp64)
StreamOps.time_zero(::Type{Timestamp64}) = Timestamp64(0)

function run()
    g = StreamGraph()

    values = source!(g, :values, out=Int, init=0)
    # buffer = sink!(g, :buffer, Buffer{Int}())

    # bind!(g, values, buffer)

    exe = compile_historic_executor(Timestamp64, g; debug=!true)

    Base.invokelatest() do
        adapter = HistoricIterable(exe, values, 
            [(Timestamp64(x), x) for x in 1:10_000_000]
        )
        
        setup!(adapter, exe)
        display(@code_native advance!(adapter, exe))
        # for _ in 1:10_000_000
        #     advance!(adapter, exe)
        # end
    end

    nothing
end

@time run()

# using ProfileView
# ProfileView.@profview run()
# VSCodeServer.@profview run()
