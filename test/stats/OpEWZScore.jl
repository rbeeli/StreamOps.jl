using Test


@testset "OpEWZScore" begin
    alpha = 0.9
    op = OpEWZScore{Float64}(alpha; next=OpReturn())
    @test op.corrected == true

    @test isnan(op(1.0))
    @test op(10.0) ≈ 0.1285648693066451
    @test op(40.0) ≈ 0.14023537540722666
    @test op(-30.0) ≈ -0.14051819888623016
    @test op(12.0) ≈ 0.12156585705875791
    @test op(13.0) ≈ 0.046604590294051125
    @test op(3.0) ≈ -0.12923992259611067
end


@testset "OpEWZScore: Constant (uncorrected bias)" begin
    alpha = 0.9
    op = OpEWZScore{Float64}(alpha; corrected=false, next=OpReturn())
    @test op.corrected == false

    @test isnan(op(1.0))
    @test isnan(op(1.0))
    @test isnan(op(1.0))
end


@testset "OpEWZScore: Constant (corrected bias)" begin
    alpha = 0.9
    op = OpEWZScore{Float64}(alpha; next=OpReturn())
    @test op.corrected == true

    @test isnan(op(1.0))
    @test isnan(op(1.0))
    @test isnan(op(1.0))
end
