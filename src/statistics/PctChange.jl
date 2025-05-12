"""
Calculates the percentage change of consecutive values.

# Formula
`` y = x\\_t / x\\_{t-1} - 1 ``
"""
mutable struct PctChange{In <: Number, Out <: Number} <: StreamOperation
	const min_count::Int
	const init_current::In
	const init_pct_change::Out
	current::In
	pct_change::Out
	counter::Int

	function PctChange{In, Out}(
		;
		current = zero(In),
		pct_change = zero(Out),
		min_count::Int = 2,
	) where {In <: Number, Out <: Number}
		new{In, Out}(
			min_count, # min_count
			current, # init_current
			pct_change, # init_pct_change
			current, # current
			pct_change, # pct_change
			0, # counter
		)
	end
end

function reset!(op::PctChange)
	op.current = op.init_current
	op.pct_change = op.init_pct_change
	op.counter = 0
	nothing
end

@inline function (op::PctChange{In, Out})(executor, value::In) where {In, Out}
	if op.counter > 0
		op.pct_change = value / op.current - one(Out)
	end
	op.current = value
	op.counter += 1
	nothing
end

@inline is_valid(op::PctChange) = op.counter >= op.min_count

@inline get_state(op::PctChange) = op.pct_change
