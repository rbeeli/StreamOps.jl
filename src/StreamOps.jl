module StreamOps


# operations
include("ops/Collect.jl")
include("ops/Combine.jl")
include("ops/Diff.jl")
include("ops/ForwardFill.jl")
include("ops/Func.jl")
include("ops/Hook.jl")
include("ops/Lag.jl")
include("ops/FracChange.jl")
include("ops/Prev.jl")
include("ops/Print.jl")
include("ops/SlidingWindow.jl")
# include("ops/Timestamper.jl")

export Collect, Combine, Diff, ForwardFill, Func, Hook, Lag, FracChange, Prev, Print, SlidingWindow


# aggregations
include("ops/Aggregate.jl")
export Aggregate, round_origin


# statistics
include("stats/EWMean.jl")
include("stats/EWStd.jl")
include("stats/EWZScore.jl")
include("stats/Mean.jl")
include("stats/Skew.jl")
include("stats/Std.jl")
include("stats/ZScore.jl")

export EWMean, EWStd, EWZScore, Mean, Skew, Std, ZScore



# stream sources
include("srcs/StreamSource.jl")
include("srcs/DataFrameRowSource.jl")
include("srcs/IterableSource.jl")
include("srcs/PeriodicSource.jl")

export StreamSource, DataFrameRowSource, IterableSource, PeriodicSource, next!


# # simulation functionality
# include("simulation.jl")

# export simulate_chronological_stream 


include("macros.jl")

export @streamops, @filter

end
