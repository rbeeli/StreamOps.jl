using Test
using StreamOps

# To run a subset of tests, call Pkg.test as follows:
#
#   Pkg.test("StreamOps", test_args=["statistics/OpStd.jl"])

requested_tests = ARGS

if isempty(requested_tests)
    include("ops/OpForwardFill.jl")
    include("ops/OpFunc.jl")
    include("ops/OpLag.jl")
    include("ops/OpNone.jl")
    include("ops/OpFracChange.jl")
    include("ops/OpPrev.jl")
    include("ops/OpPrint.jl")
    include("ops/OpReturn.jl")
    include("ops/OpSlidingWindow.jl")
    include("statistics/OpEWMean.jl")
    include("statistics/OpEWStd.jl")
    include("statistics/OpEWZScore.jl")
    include("statistics/OpMean.jl")
    include("statistics/OpSkew.jl")
    include("statistics/OpStd.jl")
    include("statistics/OpZScore.jl")
else
    println('-' ^ 60)
    println("Running subset of tests:")
    for test in requested_tests
        println("  $test")
    end
    println('-' ^ 60)

    for test in requested_tests
        include(test)
    end
end
