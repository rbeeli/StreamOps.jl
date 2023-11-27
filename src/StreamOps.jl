module StreamOps


# operations
include("ops/Op.jl")
include("ops/OpBroadcast.jl")
include("ops/OpCollect.jl")
include("ops/OpCombineLatest.jl")
include("ops/OpDiff.jl")
include("ops/OpDropIf.jl")
include("ops/OpForwardFill.jl")
include("ops/OpFunc.jl")
include("ops/OpHook.jl")
include("ops/OpLag.jl")
include("ops/OpNone.jl")
include("ops/OpFracChange.jl")
include("ops/OpPrev.jl")
include("ops/OpPrint.jl")
include("ops/OpReturn.jl")
include("ops/OpSlidingWindow.jl")
include("ops/OpTimestamper.jl")

export Op, OpBroadcast, OpCollect, OpCombineLatest, OpDiff, OpDropIf, OpForwardFill, OpFunc, OpHook, OpLag, OpNone, OpFracChange, OpPrev, OpPrint, OpReturn, OpSlidingWindow
export OpTimestamper, flush!


# statistics
include("stats/OpEWMean.jl")
include("stats/OpEWStd.jl")
include("stats/OpEWZScore.jl")
include("stats/OpMean.jl")
include("stats/OpSkew.jl")
include("stats/OpStd.jl")
include("stats/OpZScore.jl")

export OpEWMean, OpEWStd, OpEWZScore, OpMean, OpSkew, OpStd, OpZScore


# aggregations
include("aggs/AggPeriodFn.jl")

export AggPeriodFn, round_origin


# stream sources
include("srcs/StreamSource.jl")
include("srcs/DataFrameRowSource.jl")
include("srcs/IterableSource.jl")
include("srcs/PeriodicSource.jl")

export StreamSource, DataFrameRowSource, IterableSource, PeriodicSource, next!


# simulation functionality
include("simulation.jl")

export simulate_chronological_stream 


# pipeline
include("pipeline.jl")

export @pipeline

end
