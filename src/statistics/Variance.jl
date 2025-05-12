using DataStructures

"""
Calculates the simple moving variance with fixed window size in O(1) time.

# Arguments
- `window_size`: The number of observations to consider in the moving window.
- `corrected=true`: Use Bessel's correction to compute the unbiased sample variance.
- `std=false`: Compute the standard deviation instead of the variance by taking the square root of the variance.

# References
https://web.archive.org/web/20181222175223/http://people.ds.cam.ac.uk/fanf2/hermes/doc/antiforgery/stats.pdf
https://jonisalonen.com/2013/deriving-welfords-method-for-computing-variance/
"""
mutable struct Variance{In <: Number, Out <: Number, corrected, std} <: StreamOperation
	const buffer::CircularBuffer{In}
	const window_size::Int
	const corrected::Bool
	const std::Bool
	M1::Out
	M2::Out

	function Variance{In, Out}(
		window_size::Int
		;
		corrected::Bool = true,
		std::Bool = false,
	) where {In <: Number, Out <: Number}
		@assert window_size > 0 "Window size must be greater than 0"
		new{In, Out, corrected, std}(
			CircularBuffer{In}(window_size),
			window_size,
			corrected,
			std,
			zero(Out), # M1
			zero(Out), # M2
		)
	end
end

function reset!(
	op::Variance{In, Out, corrected, std},
) where {In, Out, corrected, std}
	empty!(op.buffer)
	op.M1 = zero(Out)
	op.M2 = zero(Out)
	nothing
end

@inline function (op::Variance{In})(executor, value::In) where {In <: Number}
	if isfull(op.buffer)
		dropped = popfirst!(op.buffer)
		n1 = length(op.buffer)
		delta = dropped - op.M1
		delta_n = delta / n1
		op.M1 -= delta_n
		op.M2 -= delta * (dropped - op.M1)
	else
		n1 = length(op.buffer)
	end

	n = n1 + 1
	push!(op.buffer, value)

	# update states
	delta = value - op.M1
	delta_n = delta / n
	term1 = delta * delta_n * n1
	op.M1 += delta_n
	op.M2 += term1

	nothing
end

@inline function is_valid(op::Variance{In, Out}) where {In, Out}
	isfull(op.buffer)
end

# biased variance
@inline function get_state(op::Variance{In, Out, false, false})::Out where {In, Out}
	op.window_size > 0 ? op.M2 / op.window_size : zero(Out)
end

# biased std. deviation
@inline function get_state(op::Variance{In, Out, false, true})::Out where {In, Out}
	# due to floating-point rounding errors in Welford’s online update formula,
	# M2 can become slightly negative, potentially leading to negative values under the sqrt,
	# therefore, need to ensure >= 0
	op.window_size > 0 ? sqrt(max(zero(Out), op.M2 / op.window_size)) : zero(Out)
end

# unbiased variance
@inline function get_state(op::Variance{In, Out, true, false})::Out where {In, Out}
	op.window_size > 1 ? op.M2 / (op.window_size - 1) : zero(Out)
end

# unbiased std. deviation
@inline function get_state(op::Variance{In, Out, true, true})::Out where {In, Out}
	# due to floating-point rounding errors in Welford’s online update formula,
	# M2 can become slightly negative, potentially leading to negative values under the sqrt,
	# therefore, need to ensure >= 0
	op.window_size > 1 ? sqrt(max(zero(Out), op.M2 / (op.window_size - 1))) : zero(Out)
end
