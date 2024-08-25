import pandas as pd
import numpy as np


def gen(values, alpha, adjust=True, bias=True):
    df = pd.DataFrame({"value": values})
    ewm = df["value"].ewm(alpha=alpha, adjust=adjust)
    ewm_mean = ewm.mean()
    ewm_var = ewm.var(bias=bias)
    ewm_std = np.sqrt(ewm_var)
    ewzscore = (df["value"] - ewm_mean) / ewm_std
    return ewzscore.tolist()


# Test case 1: corrected=true (adjust=True, bias=False in pandas)
print("Test case 1: corrected=true")
values1 = [1.0, 2.0, 3.0, 4.0, 1.0, 2.0, 3.0, 4.0, 1.0, 2.0]
alpha1 = 0.1
result1 = gen(values1, alpha1, adjust=True, bias=False)
print("\nFinal EW Z-Score values:")
print(result1)

# Test case 2: corrected=false (adjust=False, bias=True in pandas)
print("\nTest case 2: corrected=false")
values2 = [1.0, 2.0, 3.0, 4.0, 1.0, 2.0, 3.0, 4.0, 1.0, 2.0]
alpha2 = 0.2
result2 = gen(values2, alpha2, adjust=False, bias=True)
print("\nFinal EW Z-Score values:")
print(result2)

# Edge case: Constant values
print("\nEdge case: Constant values")
values3 = [2.0, 2.0, 2.0, 2.0, 2.0, 2.0]
alpha3 = 0.1
result3 = gen(values3, alpha3, adjust=True, bias=False)
print("\nFinal EW Z-Score values:")
print(result3)
