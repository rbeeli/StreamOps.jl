using Test
using StreamOps


@testset verbose = true "Combine" begin

    @testset "initialization" begin
        op = Combine{Tuple{Symbol,Float64}}(
            2,
            slot_fn=x -> Dict(
                :a => 1,
                :b => 2
            )[x[1]]
        )
        @test length(op.latest) == 2
        @test all(isnothing, op.latest)
    end

    @testset "default tuples" begin
        op = Combine{Tuple{Symbol,Float64}}(
            2;
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
        op = Combine{Tuple{Symbol,Float64}}(
            2;
            slot_fn=x -> Dict(
                :a => 1,
                :b => 2
            )[x[1]],
            combine_fn=x -> collect(x)
        )
        @test op((:a, 1.0)) isa Vector
    end

end
