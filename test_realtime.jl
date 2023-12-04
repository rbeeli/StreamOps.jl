using Dates

include("src/macros.jl");
include("src/simulation.jl");
include("src/ops/Func.jl");
include("src/ops/Print.jl");
include("src/ops/Combine.jl");
include("src/ops/Collect.jl");
include("src/srcs/StreamSource.jl");
include("src/srcs/IterableSource.jl");


function producer1(c::Channel)
    for i=1:1_000_000
        put!(c, (1, (Dates.now(), i)))
        sleep(0.3)
    end
end

function producer2(c::Channel)
    while true
        put!(c, (2, (Dates.now(), rand())))
        sleep(0.7)
    end
end

function producer3(c::Channel)
    while true
        put!(c, (3, (Dates.now(), rand()*100)))
        sleep(1.5)
    end
end

function consumer(c::Channel)
    get_value(x) = isnothing(x) ? x : x[2]

    combiner = @streamops begin
        Combine{Tuple{Int64,Tuple{DateTime,Number}}}(
            3;
            slot_fn=x -> x[1],
            combine_fn=x -> (get_value(x[1]), get_value(x[2]), get_value(x[3]))
        )
        Print()
    end

    pipes = [
        @streamops combiner
        @streamops combiner
        @streamops combiner
    ]

    while true
        data = take!(c)
        ix = data[1]
        pipes[ix](data)
    end
end


# Base.exit_on_sigint(true)

const c1 = Channel(1)

# run producers in background
tasks = [
    errormonitor(@async producer1(c1))
    errormonitor(@async producer2(c1))
    errormonitor(@async producer3(c1))
]

# run consumer in main thread
consumer(c1)
