import pandas as pd
import numpy as np


def gen(values, window_size, corrected=True):
    df = pd.DataFrame({"value": values})
    moving = df["value"].rolling(window_size)
    mean_ = moving.mean()
    var_ = moving.var(ddof=1 if corrected else 0)
    std_ = np.sqrt(var_)
    zscore = (df["value"] - mean_) / std_
    return zscore.tolist()


print("Test case 1: window_size=5 corrected=true")
values1 = [1.0, 2.0, 3.0, 4.0, 1.0, 2.0, 3.0, 4.0, 1.0, 2.0]
result1 = gen(values1, 5, corrected=True)
print("\nTest case 1 Z-Score values:")
print(result1)

print("Test case 2: window_size=3 corrected=false")
values2 = [1.0, 2.0, 3.0, 4.0, 1.0, 2.0, 3.0, 4.0, 1.0, 2.0]
result2 = gen(values2, 3, corrected=False)
print("\nTest case 2 Z-Score values:")
print(result2)
