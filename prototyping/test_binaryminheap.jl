using DataStructures
using Profile
using ProfileView

# Initialize BinaryMinHeap
heap = BinaryMinHeap{Int}()

# Function to benchmark push! and pop!
function benchmark_heap_operations(n)
    # Push operations
    for i in 1:n
        push!(heap, i)
        pop!(heap)
    end
end

# Profile the benchmark function
@profile benchmark_heap_operations(10_000_000)

# Display the profiling results
ProfileView.view()
