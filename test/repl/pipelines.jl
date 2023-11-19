using Dates
# using StreamOps

include("src/sources/StreamSource.jl");
include("src/sources/StreamEvent.jl");
include("src/ops/Op.jl");

include("src/sources/PeriodicSource.jl");


periodic_source = PeriodicSource(
    id="test",
    start_date=DateTime(2017, 1, 1),
    end_date=DateTime(2017, 1, 10),
    period=Day(1),
    current_date=DateTime(2017, 1, 1),
    inclusive_end=false)

for _ in 1:12
    println(next!(periodic_source))
end