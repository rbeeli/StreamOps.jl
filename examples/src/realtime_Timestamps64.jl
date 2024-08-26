using StreamOps
using Dates
using Timestamps64

# provide overloads for custom time type
StreamOps.get_time(::Type{Timestamp64}) = now(Timestamp64)
StreamOps.default_time(::Type{Timestamp64}) = Timestamp64(0)

println("Number of Julia threads: $(Threads.nthreads())")

g = StreamGraph()

timer = source!(g, :timer, out=Timestamp64, init=Timestamp64(0))
output = sink!(g, :output, Func((exe, x) -> begin
    println("output at time $(time(exe)): $x")
end))
bind!(g, timer, output)

exe = compile_realtime_executor(Timestamp64, g, debug=!true)

start = round_origin(now(Timestamp64), Dates.Second(1), mode=RoundUp)
stop = start + Dates.Second(5)
adapters = [
    LiveTimerAdapter(exe, timer, interval=Dates.Millisecond(1000), start_time=start),
]
@time run_realtime!(exe, adapters, start_time=start, end_time=stop)
