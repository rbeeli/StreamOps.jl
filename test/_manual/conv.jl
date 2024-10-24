using BenchmarkTools

mutable struct Ctx{T}
    const conv_z::Vector{T}

    function Ctx{T}() where {T}
        conv_z = Vector{T}()
        new{T}(conv_z)
    end
end

# -------------------------------------------------------------------

function conv1(ctx::Ctx{T}, x::X, y::Y) where {T,X<:AbstractVector{T},Y<:AbstractVector{T}}
    nx = length(x)
    ny = length(y)
    nz = nx + ny - 1

    if length(ctx.conv_z) != nz
        resize!(ctx.conv_z, nz)
        fill!(ctx.conv_z, zero(T))
    end

    @inbounds for i in 1:nz
        jstart = max(1, i - ny + 1)
        jend = min(i, nx)
        sum = zero(T)
        @simd for j in jstart:jend
            sum += x[j] * y[i-j+1]
        end
        ctx.conv_z[i] = sum
    end

    istart = ceil(Int, (ny - 1) / 2) + 1
    iend = istart + nx - 1
    @inbounds ctx.conv_z[istart:iend]
end

ctx = Ctx{Float64}();
x = rand(300);
y = rand(300);
test = conv1(ctx, x, y);

display(@benchmark conv1($ctx, $x, $y))

# -------------------------------------------------------------------

function conv2(ctx::Ctx{T}, x::X, y::Y) where {T,X<:AbstractVector{T},Y<:AbstractVector{T}}
    nx, ny = length(x), length(y)
    nz = nx + ny - 1
    
    # Pre-allocate output if needed
    if length(ctx.conv_z) < nz
        resize!(ctx.conv_z, nz)
    end
    fill!(ctx.conv_z, zero(T))
    
    # For small vectors, we can use a simpler loop structure
    # This avoids repeated bound checks and simplifies indexing
    @inbounds for i in 1:nx
        xi = x[i]
        # Inner loop operates on contiguous memory
        for j in 1:ny
            ctx.conv_z[i + j - 1] += xi * y[j]
        end
    end
    
    # Calculate output range
    istart = ceil(Int, (ny - 1) / 2) + 1
    iend = istart + nx - 1
    
    return @view ctx.conv_z[istart:iend]
end

@assert all(test .≈ conv2(ctx, x, y))
display(@benchmark conv2($ctx, $x, $y))

# -------------------------------------------------------------------

function conv3(ctx::Ctx{T}, x::X, y::Y) where {T,X<:AbstractVector{T},Y<:AbstractVector{T}}
    nx, ny = length(x), length(y)
    nz = nx + ny - 1
    
    # Pre-allocate output if needed
    if length(ctx.conv_z) < nz
        resize!(ctx.conv_z, nz)
    end
    fill!(ctx.conv_z, zero(T))
    
    # Outer loop over x, inner SIMD loop over y
    @inbounds for i in 1:nx
        xi = x[i]
        # SIMD loop operates on contiguous memory of y
        @simd for j in 1:ny
            ctx.conv_z[i + j - 1] += xi * y[j]
        end
    end
    
    istart = ceil(Int, (ny - 1) / 2) + 1
    iend = istart + nx - 1
    
    return @view ctx.conv_z[istart:iend]
end

@assert all(test .≈ conv3(ctx, x, y))
display(@benchmark conv3($ctx, $x, $y))
