using Test
using StreamOps

# To run a subset of tests, call Pkg.test as follows:
#
#   Pkg.test("StreamOps", test_args=["stats/OpStd.jl"])
#   Pkg.test("StreamOps", test_args=["aggs/AggPeriodFn.jl"])
#   Pkg.test("StreamOps", test_args=["ops/OpCombineLatest.jl"])
#   Pkg.test("StreamOps", test_args=["pipelines/pipelines.jl"])

requested_tests = ARGS

if isempty(requested_tests)
    include("ops/OpCombineLatest.jl")
    include("ops/OpDropIf.jl")
    include("ops/OpForwardFill.jl")
    include("ops/OpFracChange.jl")
    include("ops/OpFunc.jl")
    include("ops/OpHook.jl")
    include("ops/OpLag.jl")
    include("ops/OpNone.jl")
    include("ops/OpPrev.jl")
    include("ops/OpPrint.jl")
    include("ops/OpReturn.jl")
    include("ops/OpSlidingWindow.jl")

    include("stats/OpEWMean.jl")
    include("stats/OpEWStd.jl")
    include("stats/OpEWZScore.jl")
    include("stats/OpMean.jl")
    include("stats/OpSkew.jl")
    include("stats/OpStd.jl")
    include("stats/OpZScore.jl")

    include("aggs/AggPeriodFn.jl")

    include("pipelines/pipelines.jl")
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
