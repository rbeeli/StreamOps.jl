# StreamOps.jl

Composable operations for efficient online processing of heterogeneous data streams.

## Background

Real-time data processing is a common requirement in many applications such as IoT, monitoring and telemetry systems, streaming analytics, financial trading, etc.
In these applications, data is continuously generated and needs to be processed in real-time to extract insights or make decisions.

Ideally, algorithms processing contiunous data streams are able to process data as it arrives using efficient online algorithms.
Online algorithms update their state with each new data point and do not require the entire dataset to be loaded into memory.
An update usually consists of a single data point, which is processed in constant time in the best case.
