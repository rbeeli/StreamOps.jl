struct ExecutionEvent{TTime}
    timestamp::TTime
    source_index::Int
    function ExecutionEvent(timestamp::TTime, source_index::Int) where {TTime}
        new{TTime}(timestamp, source_index)
    end
end

@inline Base.isless(a::ExecutionEvent{TTime}, b::ExecutionEvent{TTime}) where {TTime} = a.timestamp < b.timestamp
