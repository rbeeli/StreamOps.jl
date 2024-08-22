using Test
using StreamOps

@testset verbose = true "CombineTuple" begin

    @testset "initialization" begin
        op = CombineTuple{2,Tuple{Symbol,Float64}}(;
            slot_fn=x -> Dict(
                :a => 1,
                :b => 2
            )[x[1]],
            init_value=((:none, 0.0), (:none, 0.0))
        )
        @test length(op.state) == 2
        @test all(op.state .== [(:none, 0.0), (:none, 0.0)])
    end

    @testset "default tuples" begin
        op = CombineTuple{2,Tuple{Symbol,Float64}}(;
            slot_fn=x -> Dict(
                :a => 1,
                :b => 2
            )[x[1]],
            init_value=((:none, 0.0), (:none, 0.0))
        )
        @test all(op((:a, 1.0)) .== [(:a, 1.0), (:none, 0.0)])
        @test all(op((:b, 2.0)) .== [(:a, 1.0), (:b, 2.0)])
        @test all(op((:a, 3.0)) .== [(:a, 3.0), (:b, 2.0)])
        @test all(op((:a, -1.0)) .== [(:a, -1.0), (:b, 2.0)])
    end

end
