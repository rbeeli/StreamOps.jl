using DataStructures

module _ModifiedSinc

"""
    smoothMS(data::AbstractVector{T}, deg::Int, m::Int) where T

Smoothes a vector `data` with a modified sinc kernel.
The `deg` parameter specifies the degree of the polinomial
and `m` the halfwidth of the kernel.
"""
function smoothMS(data::AbstractVector{T}, deg::Int, m::Int) where {T}
    kernel = kernelMS(deg, m, T)
    fitWeights = edgeWeights(deg, m, T)
    extData = extendData(data, m, fitWeights)
    smoothedExtData = conv(extData, kernel)
    @inbounds @view smoothedExtData[m+1:end-m]
end

# Calculates the MS convolution kernel
function kernelMS(deg::Int, m::Int, T::Type)
    coeffs = corrCoeffsMS(deg, T)
    kappa = Vector{T}(undef, size(coeffs, 1))
    for (i, row) in enumerate(eachrow(coeffs))
        @inbounds kappa[i] = row[1] + row[2] / (row[3] - m)^3
    end
    nuMinus2 = (rem(T(deg) / 2, 2) == 1) ? T(-1) : T(0)
    kernel = zeros(T, m * 2 + 1)
    kernel[m+1] = windowMS(T(0), 4) # center element
    for i in 1:m
        x = T(i) / (m + 1)
        w = windowMS(x, 4)
        a = sin((T(deg) / 2 + 2) * pi * x) / ((T(deg) / 2 + 2) * pi * x)
        for (j, k) in enumerate(kappa)
            a += k * x * sin((2 * j + nuMinus2) * pi * x)
        end
        a *= w
        @inbounds kernel[m+1-i] = a
        @inbounds kernel[m+1+i] = a
    end
    norm = sum(kernel)
    kernel ./ norm
end

# Gaussian-like window function for the MS and MS1 kernels.
# The function reaches 0 at x=+1 and x=-1 (where the kernel ends);
# at these points also the 1st derivative is very close to zero.
@inline function windowMS(x::T, alpha) where {T}
    alphaT = T(alpha)
    exp(-alphaT * x^2) + exp(-alphaT * (x + 2)^2) + exp(-alphaT * (x - 2)^2) - (2exp(-alphaT) + exp(-9alphaT))
end


# Correction coefficients for a flat passband of the MS kernel
const CORR_COEFS_F64 = Dict(
    2 => Matrix{Float64}(undef, 0, 0),
    4 => Matrix{Float64}(undef, 0, 0),
    6 => Float64[0.001717576 0.02437382 1.64375;],
    8 => Float64[0.0043993373 0.088211164 2.359375; 0.006146815 0.024715371 3.6359375],
    10 => Float64[0.0011840032 0.04219344 2.746875; 0.0036718843 0.12780383 2.7703125]
)

const CORR_COEFS_F32 = Dict(
    2 => Matrix{Float32}(undef, 0, 0),
    4 => Matrix{Float32}(undef, 0, 0),
    6 => Float32[0.001717576 0.02437382 1.64375;],
    8 => Float32[0.0043993373 0.088211164 2.359375; 0.006146815 0.024715371 3.6359375],
    10 => Float32[0.0011840032 0.04219344 2.746875; 0.0036718843 0.12780383 2.7703125]
)

@inline corrCoeffsMS(deg::Int, ::Type{Float64}) = @inbounds CORR_COEFS_F64[deg]
@inline corrCoeffsMS(deg::Int, ::Type{Float32}) = @inbounds CORR_COEFS_F32[deg]

# function corrCoeffsMS(deg::Int, T::Type)
#     if deg == 2
#         return Matrix{T}(undef, 0, 0)
#     elseif deg == 4
#         return Matrix{T}(undef, 0, 0)
#     elseif deg == 6
#         return T[0.001717576 0.02437382 1.64375;]
#     elseif deg == 8
#         return T[0.0043993373 0.088211164 2.359375;
#             0.006146815 0.024715371 3.6359375]
#     elseif deg == 10
#         return T[0.0011840032 0.04219344 2.746875;
#             0.0036718843 0.12780383 2.7703125]
#     else
#         error("Invalid deg")
#     end
# end

# Hann-square weights for linear fit at the edges, for MS smoothing.
function edgeWeights(deg, m, ::Type{T}) where {T}
    beta = T(0.70) + T(0.14) * exp(T(-0.6) * (deg - 4))
    fitLengthD = ((m + 1) * beta) / (T(1.5) + T(0.5) * deg)
    fitLength = floor(Int, fitLengthD)
    w = zeros(T, fitLength + 1)
    for i in 1:fitLength+1
        cosine = cos(T(0.5) * pi * (i - 1) / fitLengthD)
        @inbounds w[i] = cosine^2
    end
    w
end

function extendData(data::D, m, fitWeights::Vector{T}) where {T,D<:AbstractVector{T}}
    datLength = length(data)
    extData = zeros(T, datLength + 2 * m)
    fitLength = length(fitWeights)
    fitY = @view data[1:fitLength]
    offset, slope = fitWeightedLinear(fitY, fitWeights)
    @inbounds extData[1:m] = offset .+ (-m+1:0) * slope
    @inbounds extData[m+1:datLength+m] = data
    fitY = reverse(@view data[(datLength-fitLength+1):datLength])
    offset, slope = fitWeightedLinear(fitY, fitWeights)
    @inbounds extData[datLength+m+1:datLength+2*m] = offset .+ (0:-1:-m+1) * slope
    extData
end

function fitWeightedLinear(yData::AbstractVector{T}, weights) where T
    n = length(yData)
    sumWeights = sum(weights)
    
    sumX::T = 0
    sumY::T = 0
    sumX2::T = 0
    sumXY::T = 0
    
    @inbounds for i in 1:n
        wᵢ = weights[i]
        x_ = i * wᵢ
        y_ = yData[i] * wᵢ
        
        sumX += x_
        sumY += y_
        sumX2 += i * x_
        sumXY += i * y_
    end
    
    varX2 = sumX2 * sumWeights - sumX * sumX
    slope = varX2 == 0 ? zero(T) : (sumXY * sumWeights - sumX * sumY) / varX2
    offset = (sumY - slope * sumX) / sumWeights
    
    offset, slope
end

# """
# This function behaves the same way as the conv function in
# Matlab/Octave, here only the "same" option is implemented.
# """
# function conv(x::X, y::Y) where {T,X<:AbstractVector{T},Y<:AbstractVector{T}}
#     nx = length(x)
#     ny = length(y)
#     nz = nx + ny - 1
#     z = zeros(T, nz)
#     for i in 1:nz
#         for j in max(1, i - ny + 1):min(i, nx)
#             @inbounds z[i] += x[j] * y[i-j+1]
#         end
#     end
#     # Return only the "same" part of the result
#     istart = ceil(Int, (ny - 1) / 2) + 1
#     iend = istart + nx - 1
#     @inbounds z[istart:iend]
# end

# Using SIMD and precomputed indices
function conv(x::X, y::Y) where {T,X<:AbstractVector{T},Y<:AbstractVector{T}}
    nx = length(x)
    ny = length(y)
    nz = nx + ny - 1
    z = zeros(T, nz)

    @inbounds for i in 1:nz
        jstart = max(1, i - ny + 1)
        jend = min(i, nx)
        sum = zero(T)
        @simd for j in jstart:jend
            sum += x[j] * y[i-j+1]
        end
        z[i] = sum
    end

    istart = ceil(Int, (ny - 1) / 2) + 1
    iend = istart + nx - 1
    @inbounds z[istart:iend]
end

end


"""
Calculates the moving Modified Sinc filter with fixed window size.

The filter predicts the smoothed value at the end of the window.
"""
mutable struct ModifiedSinc{In<:Number,Out<:Number} <: StreamOperation
    const buffer::CircularBuffer{In}
    const window_size::Int
    const order::Int
    filtered::Out

    function ModifiedSinc{In,Out}(
        window_size::Int,
        order::Int
    ) where {In<:Number,Out<:Number}
        @assert window_size > 0 "Window size must be greater than 0"
        @assert order ∈ (2, 4, 6, 8, 10) "Order must one of 2, 4, 6, 8, 10"
        new{In,Out}(
            CircularBuffer{In}(window_size),
            window_size,
            order,
            zero(Out), # filtered
        )
    end
end

@inline function (op::ModifiedSinc{In})(executor, value::In) where {In<:Number}
    push!(op.buffer, value)
    if length(op.buffer) < op.window_size
        op.filtered = value
    else
        op.filtered = _ModifiedSinc.smoothMS(op.buffer, op.order, op.window_size)[end]
    end
    nothing
end

@inline function is_valid(op::ModifiedSinc{In,Out}) where {In,Out}
    !isempty(op.buffer)
end

@inline function get_state(op::ModifiedSinc{In,Out})::Out where {In,Out}
    op.filtered
end
