module StreamOps

include("utils.jl")

export round_origin

# operations
include("ops/Apply.jl")
include("ops/Collect.jl")
include("ops/Combine.jl")
include("ops/CombineTuple.jl")
include("ops/Diff.jl")
include("ops/ForwardFill.jl")
include("ops/Transform.jl")
include("ops/Hook.jl")
include("ops/Lag.jl")
include("ops/FracChange.jl")
include("ops/Prev.jl")
include("ops/Print.jl")
include("ops/RollingWindow.jl")
include("ops/Aggregate.jl")
include("ops/Sample.jl")
include("ops/Counter.jl")
include("ops/Accumulate.jl")

export Apply, Collect, Combine, CombineTuple, Diff, ForwardFill, Transform, Hook, Lag, FracChange
export Prev, Print, RollingWindow, Counter, Accumulate
export Aggregate, Sample

# statistics
include("stats/EWMean.jl")
include("stats/EWStd.jl")
include("stats/EWZScore.jl")
include("stats/RollingMean.jl")
include("stats/RollingSkew.jl")
include("stats/RollingStd.jl")
include("stats/RollingZScore.jl")

export EWMean, EWStd, EWZScore, RollingMean, RollingSkew, RollingStd, RollingZScore

# stream sources
include("srcs/StreamSource.jl")
include("srcs/DataFrameRowSource.jl")
include("srcs/IterableSource.jl")
include("srcs/PeriodicSource.jl")

export StreamSource, DataFrameRowSource, IterableSource, PeriodicSource, next!, reset!

# simulation functionality
include("simulation.jl")

export simulate_chronological_stream

include("macros.jl")

export @streamops, @filter, @skipIf, @broadcast, @broadcast_collect

end
