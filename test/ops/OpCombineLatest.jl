using Test
using StreamOps


@testset verbose = true "OpCombineLatest Tests" begin

    @testset "Initialization" begin
        op = OpCombineLatest{Tuple{Symbol,Float64}}(;
            slot_map=Dict(
                :a => 1,
                :b => 2
            ),
            key_fn=x -> x[1],
            next=OpReturn()
        )
        @test length(op.latest) == 2
        @test all(isnothing, op.latest)
    end

    @testset "Stream Combination" begin
        op = OpCombineLatest{Tuple{Symbol,Float64}}(;
            slot_map=Dict(
                :a => 1,
                :b => 2
            ),
            key_fn=x -> x[1],
            next=OpReturn()
        )
        @test all(op((:a, 1.0)) .== [(:a, 1.0), nothing])
        @test all(op((:b, 2.0)) .== [(:a, 1.0), (:b, 2.0)])
        @test all(op((:a, 3.0)) .== [(:a, 3.0), (:b, 2.0)])
        @test all(op((:a, -1.0)) .== [(:a, -1.0), (:b, 2.0)])
    end

    @testset "Key not in slot index" begin
        op = OpCombineLatest{Tuple{Symbol,Float64}}(;
            slot_map=Dict(
                :a => 1,
                :b => 2
            ),
            key_fn=x -> x[1],
            next=OpReturn()
        )
        @test_throws ArgumentError op((:WRONG, 1.0))
        @test_throws "Key `WRONG` not in slot index. Valid keys: [:a, :b]" op((:WRONG, 1.0))
    end

end
