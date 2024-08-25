using Test
using StreamOps
using Suppressor

@testset verbose = true "Print" begin
    
    @testset "default" begin
        g = StreamGraph()

        values = source!(g, :values, out=Int, init=0)
        buffer = sink!(g, :buffer, Print())

        bind!(g, values, buffer)

        exe = compile_historic_executor(DateTime, g; debug=!true)

        start = DateTime(2000, 1, 1)
        stop = DateTime(2000, 1, 4)
        adapters = [
            IterableAdapter(exe, values, [
                (DateTime(2000, 1, 1), 1),
                (DateTime(2000, 1, 2), 2),
                (DateTime(2000, 1, 3), 3),
                (DateTime(2000, 1, 4), 4)
            ])
        ]
        output = @capture_out begin
            run_simulation!(exe, adapters; start_time=start, end_time=stop)
        end
        @test output == "1\n2\n3\n4\n"
    end

end
