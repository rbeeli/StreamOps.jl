using Test
using StreamOps

@testset verbose = true "Combine" begin

    @testset "initialization" begin
        op = Combine{2,Tuple{Symbol,Float64}}(;
            slot_fn=x -> Dict(
                :a => 1,
                :b => 2
            )[x[1]]
        )
        @test length(op.state) == 2
        @test all(isnothing, op.state)
    end

    @testset "default tuples" begin
        op = Combine{2,Tuple{Symbol,Float64}}(;
            slot_fn=x -> Dict(
                :a => 1,
                :b => 2
            )[x[1]]
        )
        @test all(op((:a, 1.0)) .== [(:a, 1.0), nothing])
        @test all(op((:b, 2.0)) .== [(:a, 1.0), (:b, 2.0)])
        @test all(op((:a, 3.0)) .== [(:a, 3.0), (:b, 2.0)])
        @test all(op((:a, -1.0)) .== [(:a, -1.0), (:b, 2.0)])
    end

    @testset "combine_fn" begin
        op = Combine{2,Tuple{Symbol,Float64}}(;
            slot_fn=x -> Dict(
                :a => 1,
                :b => 2
            )[x[1]],
            combine_fn=x -> collect(x)
        )
        @test op((:a, 1.0)) isa Vector
    end

end
