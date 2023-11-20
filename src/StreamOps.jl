module StreamOps

include("ops/Op.jl")
include("ops/OpCombineLatest.jl")
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
export Op, OpCombineLatest, OpDropIf, OpForwardFill, OpFunc, OpHook, OpLag, OpNone, OpFracChange, OpPrev, OpPrint, OpReturn, OpSlidingWindow

include("stats/OpEWMean.jl")
include("stats/OpEWStd.jl")
include("stats/OpEWZScore.jl")
include("stats/OpMean.jl")
include("stats/OpSkew.jl")
include("stats/OpStd.jl")
include("stats/OpZScore.jl")
export OpEWMean, OpEWStd, OpEWZScore, OpMean, OpSkew, OpStd, OpZScore

include("aggs/AggPeriodFn.jl")
export AggPeriodFn, round_origin

include("srcs/StreamSource.jl")
include("srcs/StreamEvent.jl")
include("srcs/DataFrameSource.jl")
include("srcs/IterableSource.jl")
include("srcs/PeriodicSource.jl")
export StreamSource, StreamEvent, DataFrameSource, IterableSource, PeriodicSource, next!

include("srcs/simulation.jl")
export simulate_chronological_stream

include("pipeline.jl")
export @pipeline

end