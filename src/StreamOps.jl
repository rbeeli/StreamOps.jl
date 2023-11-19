module StreamOps

include("sources/StreamSource.jl")
include("sources/StreamEvent.jl")
include("sources/DataFrameSource.jl")
include("sources/IterableSource.jl")
include("sources/PeriodicSource.jl")
export StreamSource, StreamEvent, DataFrameSource, IterableSource, PeriodicSource, next!

include("sources/simulation.jl")
export simulate_chronological_stream

include("ops/Op.jl")
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
export Op, OpForwardFill, OpFunc, OpHook, OpLag, OpNone, OpFracChange, OpPrev, OpPrint, OpReturn, OpSlidingWindow

include("statistics/OpEWMean.jl")
include("statistics/OpEWStd.jl")
include("statistics/OpEWZScore.jl")
include("statistics/OpMean.jl")
include("statistics/OpSkew.jl")
include("statistics/OpStd.jl")
include("statistics/OpZScore.jl")
export OpEWMean, OpEWStd, OpEWZScore, OpMean, OpSkew, OpStd, OpZScore

include("pipeline.jl")
export @pipeline

end