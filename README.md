# StreamOps.jl

Composable operations for efficient online processing of realtime and historical data streams using directed graphs.

## Background

Real-time data processing is a common requirement in many applications such as IoT, monitoring, telemetry systems, streaming analytics, financial trading, etc.
In these applications, data is continuously generated and needs to be processed in real-time in order to extract insights and take decisions.

Algorithms processing continuous data streams are able to process data as it arrives using efficient [online algorithms](https://en.wikipedia.org/wiki/Online_algorithm).
Online algorithms update their state with each new data point and do not require the entire dataset to be loaded into memory.
An update usually consists of a single data point. In the best case, the update is processed in constant time and takes constant memory.
