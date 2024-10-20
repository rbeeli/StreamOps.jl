using Test
using StreamOps
using LinearAlgebra

@testset verbose = true "SavitzkyGolay" begin

    function savitzky_golay(y, window_size, order)
        N = length(y)
        y_filtered = zeros(Float64, N)
        h_dict = precompute_h(window_size, order)
        @inbounds for t = 1:N
            n_t = min(t, window_size)
            h = h_dict[n_t]
            y_window = y[(t - n_t + 1):t]
            y_filtered[t] = dot(h, y_window)
        end
        y_filtered
    end

    function precompute_h(window_size, order)
        h_dict = Dict{Int, Vector{Float64}}()
    
        for n = 1:window_size
            m = min(order, n - 1)
            s = [-(n - 1) + k for k in 0:(n - 1)]  # s_k values
            A = zeros(n, m + 1)
    
            for k = 1:n
                @inbounds for j = 1:(m + 1)
                    A[k, j] = s[k]^(j - 1)
                end
            end
    
            c = zeros(m + 1)
            c[1] = 1  # For smoothing (0th derivative)
            ATA = transpose(A) * A
            ATAc = ATA \ c
            h = A * ATAc  # h is now a Vector{Float64}
            h_dict[n] = h
        end
    
        h_dict
    end

    @testset "order=1" begin
        for window_size in [1,2,3,4,5,6,7,8,9,10]
            g = StreamGraph()
            values = source!(g, :values, out=Int, init=0)
            avg = op!(g, :avg, SavitzkyGolay{Int,Float64}(window_size, 1), out=Float64)
            output = sink!(g, :output, Buffer{Float64}())
            bind!(g, values, avg)
            bind!(g, avg, output)

            states = compile_graph!(DateTime, g)
            exe = HistoricExecutor{DateTime}(g, states)
            setup!(exe)

            vals = [1, 2, 3, 4, 1, -4, 3, 0, 9, 2, 3, 4, 1, 2, 3, 4, 1, 2, 3, 4]
            set_adapters!(exe, [
                HistoricIterable(exe, values, [(DateTime(2000, 1, i), x) for (i, x) in enumerate(vals)])
            ])
            run!(exe, DateTime(2000, 1, 1), DateTime(2000, 1, length(vals)))
            @test output.operation.buffer ≈ savitzky_golay(vals, window_size, 1)
        end
    end

    @testset "order=2" begin
        for window_size in [1,2,3,4,5,6,7,8,9,10]
            g = StreamGraph()
            values = source!(g, :values, out=Int, init=0)
            avg = op!(g, :avg, SavitzkyGolay{Int,Float64}(window_size, 2), out=Float64)
            output = sink!(g, :output, Buffer{Float64}())
            bind!(g, values, avg)
            bind!(g, avg, output)

            states = compile_graph!(DateTime, g)
            exe = HistoricExecutor{DateTime}(g, states)
            setup!(exe)

            vals = [1, 2, 3, 4, 1, -4, 3, 0, 9, 2, 3, 4, 1, 2, 3, 4, 1, 2, 3, 4]
            set_adapters!(exe, [
                HistoricIterable(exe, values, [(DateTime(2000, 1, i), x) for (i, x) in enumerate(vals)])
            ])
            run!(exe, DateTime(2000, 1, 1), DateTime(2000, 1, length(vals)))
            @test output.operation.buffer ≈ savitzky_golay(vals, window_size, 2)
        end
    end

    @testset "order=3" begin
        for window_size in [1,2,3,4,5,6,7,8,9,10]
            g = StreamGraph()
            values = source!(g, :values, out=Int, init=0)
            avg = op!(g, :avg, SavitzkyGolay{Int,Float64}(window_size, 3), out=Float64)
            output = sink!(g, :output, Buffer{Float64}())
            bind!(g, values, avg)
            bind!(g, avg, output)

            states = compile_graph!(DateTime, g)
            exe = HistoricExecutor{DateTime}(g, states)
            setup!(exe)

            vals = [1, 2, 3, 4, 1, -4, 3, 0, 9, 2, 3, 4, 1, 2, 3, 4, 1, 2, 3, 4]
            set_adapters!(exe, [
                HistoricIterable(exe, values, [(DateTime(2000, 1, i), x) for (i, x) in enumerate(vals)])
            ])
            run!(exe, DateTime(2000, 1, 1), DateTime(2000, 1, length(vals)))
            @test output.operation.buffer ≈ savitzky_golay(vals, window_size, 3)
        end
    end

end
