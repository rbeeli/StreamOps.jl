#     @testitem "w/ RealtimeIterable" begin
    # using Dates
    
#         g = StreamGraph()

#         buffer = Float64[]
#         source!(g, :values, out=Float64, init=0.0)
#         sink!(g, :output, Buffer{Float64}(buffer))
#         bind!(g, :values, :output)

#         exe = compile_realtime_executor(DateTime, g, debug=!true)

#         start = now()
#         stop = now() + Millisecond(2000)
#         set_adapters!(exe, [
#             RealtimeIterable(exe, g[:values], [
#                 (start, 1.0),
#                 (start + Millisecond(1), 2.0),
#             ])
#         ])
#         @time run!(exe, start, stop)

#         @test length(buffer) == 2
#         @test all(buffer .== [1.0, 2.0])
#     end

#     # @testitem "w/ RealtimeTimer" begin
    # using Dates

#     #     g = StreamGraph()

#     #     buffer = DateTime[]
#     #     source!(g, :time, out=DateTime, init=DateTime(0))
#     #     sink!(g, :output, Buffer{DateTime}(buffer))
#     #     bind!(g, :time, :output)

#     #     exe = compile_realtime_executor(DateTime, g, debug=!true)

#     #     start = now()
#     #     stop = now() + Millisecond(500)
#     #     set_adapters!(exe, [
#     #         RealtimeTimer{DateTime}(exe, g[:time], interval=Millisecond(50), start_time=start)
#     #     ])
#     #     @time run!(exe, start, stop)

#     #     @test length(buffer) == >
#     #     @test all(buffer .>= start)
#     #     @test all(buffer .<= stop)
#     # end
