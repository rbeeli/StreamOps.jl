struct ExecutionEvent{TTime,TAdapter}
    timestamp::TTime
    adapter::TAdapter

    function ExecutionEvent(timestamp::TTime, adapter::TAdapter) where {TTime,TAdapter}
        new{TTime,TAdapter}(timestamp, adapter)
    end
end

@inline Base.isless(a::ExecutionEvent{TTime}, b::ExecutionEvent{TTime}) where {TTime} =
    a.timestamp < b.timestamp

export ExecutionEvent
