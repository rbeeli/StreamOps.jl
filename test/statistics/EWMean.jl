using Test
using StreamOps

@testset verbose = true "EWMean" begin

@testset "alpha=0.9 corrected=false" begin
    g = StreamGraph()

    values = source!(g, :values, out=Float64, init=0.0)
    avg = op!(g, :avg, EWMean{Float64,Float64}(alpha=0.9, corrected=false), out=Float64)
    output = sink!(g, :output, Buffer{Float64}())

    bind!(g, values, avg)
    bind!(g, avg, output)

    exe = compile_historic_executor(DateTime, g; debug=!true)
    
    start = DateTime(2000, 1, 1)
    stop = DateTime(2000, 1, 7)
    adapters = [
        IterableAdapter(exe, values, [
            (DateTime(2000, 1, 1), 50.0),
            (DateTime(2000, 1, 2), 1.5),
            (DateTime(2000, 1, 3), 1.1),
            (DateTime(2000, 1, 4), 4.0),
            (DateTime(2000, 1, 5), -3.0),
            (DateTime(2000, 1, 6), 150.0),
            (DateTime(2000, 1, 7), -400.0)
        ])
    ]
    run_simulation!(exe, adapters; start_time=start, end_time=stop)

    # import pandas as pd
    # with pd.option_context('display.float_format', '{:0.8f}'.format):
    #     df = pd.DataFrame({'B': [50.0, 1.5, 1.1, 4.0, -3.0, 150.0, -400.0]})
    #     print(df.ewm(alpha=0.9, adjust=False).mean().to_string(index=False))    
    expected = [
        50.00000000
        6.35000000
        1.62500000
        3.76250000
        -2.32375000
        134.76762500
        -346.52323750
    ]
    @test output.operation.buffer ≈ expected
end

@testset "alpha=0.9 corrected=true(default)" begin
    g = StreamGraph()

    values = source!(g, :values, out=Float64, init=0.0)
    avg = op!(g, :avg, EWMean{Float64,Float64}(alpha=0.9), out=Float64)
    output = sink!(g, :output, Buffer{Float64}())

    bind!(g, values, avg)
    bind!(g, avg, output)

    exe = compile_historic_executor(DateTime, g; debug=!true)
    
    start = DateTime(2000, 1, 1)
    stop = DateTime(2000, 1, 7)
    adapters = [
        IterableAdapter(exe, values, [
            (DateTime(2000, 1, 1), 50.0),
            (DateTime(2000, 1, 2), 1.5),
            (DateTime(2000, 1, 3), 1.1),
            (DateTime(2000, 1, 4), 4.0),
            (DateTime(2000, 1, 5), -3.0),
            (DateTime(2000, 1, 6), 150.0),
            (DateTime(2000, 1, 7), -400.0)
        ])
    ]
    run_simulation!(exe, adapters; start_time=start, end_time=stop)

    # import pandas as pd
    # with pd.option_context('display.float_format', '{:0.8f}'.format):
    #     df = pd.DataFrame({'B': [50.0, 1.5, 1.1, 4.0, -3.0, 150.0, -400.0]})
    #     print(df.ewm(alpha=0.9, adjust=True).mean().to_string(index=False))   
    expected = [
        50.00000000
        5.90909091
        1.57657658
        3.75787579
        -2.32427324
        134.76770977
        -346.52327715
    ]
    @test output.operation.buffer ≈ expected
end

@testset "alpha=0.3 corrected=true(default) (R sample)" begin
    g = StreamGraph()

    values = source!(g, :values, out=Float64, init=0.0)
    avg = op!(g, :avg, EWMean{Float64,Float64}(alpha=0.3), out=Float64)
    output = sink!(g, :output, Buffer{Float64}())

    bind!(g, values, avg)
    bind!(g, avg, output)

    exe = compile_historic_executor(DateTime, g; debug=!true)
    
    vals = Float64[1.0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0]
    start = DateTime(2000, 1, 1)
    stop = DateTime(2000, 1, length(vals))
    adapters = [
        IterableAdapter(exe, values, [
            (DateTime(2000, 1, i), x)
            for (i, x) in enumerate(vals)
        ])
    ]
    run_simulation!(exe, adapters; start_time=start, end_time=stop)

    # R sample (see _reconcile/EWMA_bias.R)
    expected = [
        1, 0.411764705882353, 0.223744292237443, 0.135412554283458, #
        0.0865818037575277, 0.0571439257166366, 0.365385791052037, #
        0.567416735650975, 0.702648817229494, 0.794447250592858, #
        0.857357006849418, 0.596539859754709, 0.415826992743039, #
        0.290227047109354, 0.202743599929962, 0.141717713044793
    ]
    @test output.operation.buffer ≈ expected
end

end
