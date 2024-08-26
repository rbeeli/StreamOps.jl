using Test
using StreamOps

@testset verbose = true "Copy" begin
    
    @testset "Copy{Vector{Int}}()" begin
        g = StreamGraph()

        values = source!(g, :values, out=Vector{Int}, init=Int[])
        buffer = op!(g, :buffer, Copy{Vector{Int}}(), out=Vector{Int})
        output = sink!(g, :output, Buffer{Vector{Int}}())

        bind!(g, values, buffer)
        bind!(g, buffer, output)

        exe = compile_historic_executor(DateTime, g; debug=!true)

        input = [1,2,3]

        start = DateTime(2000, 1, 1)
        stop = DateTime(2000, 1, 4)
        adapters = [
            IterableAdapter(exe, values, [
                (DateTime(2000, 1, 1), input)
            ])
        ]
        run_simulation!(exe, adapters, start, stop)
        @test output.operation.buffer[1] == input # same contents
        @test output.operation.buffer[1] !== input # different objects (copy)
    end
    
    @testset "Copy(Int[])" begin
        g = StreamGraph()

        values = source!(g, :values, out=Vector{Int}, init=Int[])
        buffer = op!(g, :buffer, Copy(Int[]), out=Vector{Int})
        output = sink!(g, :output, Buffer{Vector{Int}}())

        bind!(g, values, buffer)
        bind!(g, buffer, output)

        exe = compile_historic_executor(DateTime, g; debug=!true)

        input = [1,2,3]

        start = DateTime(2000, 1, 1)
        stop = DateTime(2000, 1, 4)
        adapters = [
            IterableAdapter(exe, values, [
                (DateTime(2000, 1, 1), input)
            ])
        ]
        run_simulation!(exe, adapters, start, stop)
        @test output.operation.buffer[1] == input # same contents
        @test output.operation.buffer[1] !== input # different objects (copy)
    end

end
