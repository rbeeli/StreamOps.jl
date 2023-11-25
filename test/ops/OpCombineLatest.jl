using Test
using StreamOps


@testset verbose = true "OpCombineLatest Tests" begin

    @testset "Initialization" begin
        op = OpCombineLatest{Tuple{Symbol,Float64}}(;
            n_slots=2,
            slot_fn=x -> Dict(
                :a => 1,
                :b => 2
            )[x[1]],
            next=OpReturn()
        )
        @test length(op.latest) == 2
        @test all(isnothing, op.latest)
    end

    @testset "Stream Combination" begin
        op = OpCombineLatest{Tuple{Symbol,Float64}}(;
            n_slots=2,
            slot_fn=x -> Dict(
                :a => 1,
                :b => 2
            )[x[1]],
            next=OpReturn()
        )
        @test all(op((:a, 1.0)) .== [(:a, 1.0), nothing])
        @test all(op((:b, 2.0)) .== [(:a, 1.0), (:b, 2.0)])
        @test all(op((:a, 3.0)) .== [(:a, 3.0), (:b, 2.0)])
        @test all(op((:a, -1.0)) .== [(:a, -1.0), (:b, 2.0)])
    end

end
