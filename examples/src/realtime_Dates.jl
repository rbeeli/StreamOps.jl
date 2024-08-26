using StreamOps
using Dates

println("Number of Julia threads: $(Threads.nthreads())")

g = StreamGraph()

timer = source!(g, :timer, out=DateTime, init=DateTime(0))
output = sink!(g, :output, Func((exe, x) -> begin
    println("output at time $(Dates.format(time(exe), "yyyy-mm-ddTHH:MM:SS.sss")): $x")
end))
bind!(g, timer, output)

exe = compile_realtime_executor(DateTime, g, debug=!true)

start = round_origin(now(UTC), Dates.Second(1), mode=RoundUp)
stop = start + Dates.Second(5)
adapters = [
    RealTimerAdapter(exe, timer, interval=Dates.Millisecond(1000), start_time=start),
]
@time run_realtime!(exe, adapters, start_time=start, end_time=stop)
