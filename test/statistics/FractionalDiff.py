import numpy as np
import pandas as pd


def _GetMemoryWeights(order, memoryThreshold=1e-4):
    """
    Returns an array of memory weights for each time lag.

    Parameters:
    -----------
        order           (float) Order of fracdiff
        memoryThreshold (float) Minimum magnitude of weight significance
    """
    memoryWeights = [1,]
    k = 1
    while True:
        weight = -memoryWeights[-1] * ( order - k + 1 ) / k # Iteratively generate next lag weight
        if abs(weight) < memoryThreshold:
            break
        memoryWeights.append(weight)
        k += 1
    return np.array(list(reversed(memoryWeights)))

def _FracDiff(ts, order=1, memoryThreshold=1e-4):
    """
    Differentiates a time series based on a real-valued order.

    Parameters:
    -----------
        ts            (pandas.Series) Univariate time series
        order         (float) Order of differentiation
        memoryWeights (array) Optional pre-computed weights
    """
    memoryWeights = _GetMemoryWeights(order, memoryThreshold=memoryThreshold)

    K = len(memoryWeights)
    # print("Memory Weights: ", memoryWeights)
    fracDiffedSeries = ts.rolling(K).apply(lambda x: np.sum( x * memoryWeights ), raw=True)
    fracDiffedSeries = fracDiffedSeries.iloc[(K-1):]
    
    return fracDiffedSeries
    
    
vals = pd.Series([50.0, 1.5, 1.1, 4.0, -3.0, 150.0, -400.0, 50.0, 1.5, 1.1, 4.0, #
        -3.0, 150.0, -400.0, 50.0, 1.5, 1.1, 4.0, -3.0, 150.0, -400.0, #
        50.0, 1.5, 1.1, 4.0, -3.0, 150.0, -400.0])

diffseries = _FracDiff(vals, order=0)
print("d=0")
print(diffseries.tolist())

diffseries = _FracDiff(vals, order=1)
print("d=1")
print(diffseries.tolist())

diffseries = _FracDiff(vals, order=0.99)
print("d=0.99")
print(diffseries.tolist())
