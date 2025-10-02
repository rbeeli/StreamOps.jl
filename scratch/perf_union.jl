using BenchmarkTools

# Union style ---------------------------------------------------------------

function union_consume!(xs)
    acc = 0.0
    @inbounds for x in xs
        if x === nothing
            acc += 1      # cheap fallback branch
        else
            acc += x      # x::Float64 here
        end
    end
    return acc
end

function union_driver(n)
    xs = Vector{Union{Nothing,Float64}}(undef, n)
    @inbounds for i in eachindex(xs)
        xs[i] = (i & 0x3 == 0x3) ? nothing : rand()
    end
    union_consume!(xs)
end

# Maybe style --------------------------------------------------------------

struct Maybe{T}
    has::Bool
    value::T
end

Maybe(x::T) where {T} = Maybe{T}(true, x)
Maybe(::Nothing) = Maybe{Float64}(false, 0.0)   # helper for init

function maybe_consume!(xs)
    acc = 0.0
    @inbounds for x in xs
        acc += x.has ? x.value : 1
    end
    return acc
end

function maybe_driver(n)
    xs = Vector{Maybe{Float64}}(undef, n)
    @inbounds for i in eachindex(xs)
        xs[i] = (i & 0x3 == 0x3) ? Maybe{Float64}(false, 0.0) : Maybe(rand())
    end
    maybe_consume!(xs)
end

# Warm-up
union_driver(10_000);
maybe_driver(10_000);

# Bench
println("Union{Float64,Nothing}")
@btime union_driver(10_000);

println("\nMaybe{Float64}")
@btime maybe_driver(10_000);
