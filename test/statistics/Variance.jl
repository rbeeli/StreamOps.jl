using Test
using StreamOps
using Statistics

@testset verbose = true "Variance" begin

@testset "window_size=5 corrected=true(default)" begin
    window_size = 5

    g = StreamGraph()

    values = source!(g, :values, out=Float64, init=0.0)
    avg = op!(g, :avg, Variance{Float64,Float64}(window_size), out=Float64)
    output = sink!(g, :output, Buffer{Float64}())

    bind!(g, values, avg)
    bind!(g, avg, output)

    exe = compile_historic_executor(DateTime, g; debug=!true)
    
    vals = [1.0, 2.0, 3.0, 4.0, 1.0, 2.0, 3.0, 4.0, 1.0, 2.0]
    start = DateTime(2000, 1, 1)
    stop = DateTime(2000, 1, length(vals))
    adapters = [
        IterableAdapter(exe, values, [
            (DateTime(2000, 1, i), x)
            for (i, x) in enumerate(vals)
        ])
    ]
    run_simulation!(exe, adapters; start_time=start, end_time=stop)
    for i in window_size:length(vals)
        @test output.operation.buffer[i-window_size+1] ≈ var(vals[i-window_size+1:i], corrected=true)
    end
end

@testset "window_size=3 corrected=false" begin
    window_size = 3

    g = StreamGraph()

    values = source!(g, :values, out=Float64, init=0.0)
    avg = op!(g, :avg, Variance{Float64,Float64}(window_size, corrected=false), out=Float64)
    output = sink!(g, :output, Buffer{Float64}())

    bind!(g, values, avg)
    bind!(g, avg, output)

    exe = compile_historic_executor(DateTime, g; debug=!true)
    
    vals = [1.0, 2.0, 3.0, 4.0, 1.0, 2.0, 3.0, 4.0, 1.0, 2.0]
    start = DateTime(2000, 1, 1)
    stop = DateTime(2000, 1, length(vals))
    adapters = [
        IterableAdapter(exe, values, [
            (DateTime(2000, 1, i), x)
            for (i, x) in enumerate(vals)
        ])
    ]
    run_simulation!(exe, adapters; start_time=start, end_time=stop)
    for i in window_size:length(vals)
        @test output.operation.buffer[i-window_size+1] ≈ var(vals[i-window_size+1:i], corrected=false)
    end
end

end
