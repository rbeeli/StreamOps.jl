using Test

@testset "frac_diff_weights: d=1" begin
    expected = [-1.0, 1.0]
    actual = frac_diff_weights(Float64, 1.0)

    for i in eachindex(expected)
        @test actual[i] ≈ expected[i] atol = 1e-6
    end
end

@testset "frac_diff_weights: d=0.99" begin
    expected = [-1.13022053e-04, -1.41101190e-04, -1.81157020e-04, -2.41140792e-04,
        -3.36923263e-04, -5.04124583e-04, -8.37416250e-04, -1.66650000e-03,
        -4.95000000e-03, -9.90000000e-01, 1.00000000e+00]
    actual = frac_diff_weights(Float64, 0.99)

    for i in eachindex(expected)
        @test actual[i] ≈ expected[i] atol = 1e-6
    end
end

@testset "FracDiff: d=1 equals first differences" begin
    op = FracDiff{Float64,Float64}(1)

    vals = [50.0, 1.5, 1.1, 4.0, -3.0, 150.0, -400.0, 50.0, 1.5, 1.1, 4.0, #
        -3.0, 150.0, -400.0, 50.0, 1.5, 1.1, 4.0, -3.0, 150.0, -400.0, #
        50.0, 1.5, 1.1, 4.0, -3.0, 150.0, -400.0]

    expected = vcat([0.0], vals[2:end] .- vals[1:end-1])

    for i in eachindex(vals)
        @test op(vals[i]) ≈ expected[i] atol = 1e-6
    end
end

@testset "FracDiff: d=0.99" begin
    op = FracDiff{Float64,Float64}(0.99)

    vals = [50.0, 1.5, 1.1, 4.0, -3.0, 150.0, -400.0, 50.0, 1.5, 1.1, 4.0, #
        -3.0, 150.0, -400.0, 50.0, 1.5, 1.1, 4.0, -3.0, 150.0, -400.0, #
        50.0, 1.5, 1.1, 4.0, -3.0, 150.0, -400.0]

    expected = [3.0735819920702734, -6.859030168988753, 153.02035742475738, #
        -548.4410855286475, 445.29766956916126, -46.23978225929855, #
        -0.053730985383909635, 3.0735819920702734, -6.859030168988753, #
        153.02035742475738, -548.4410855286475, 445.29766956916126, #
        -46.23978225929855, -0.053730985383909635, 3.0735819920702734, #
        -6.859030168988753, 153.02035742475738, -548.4410855286475]

    actual = op.(vals)
    actual = actual[11:end]
    @test length(actual) == length(expected)

    # display(hcat(expected, actual))

    for i in eachindex(expected)
        @test actual[i] ≈ expected[i] atol = 1e-6
    end
end
