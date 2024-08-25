import pandas as pd

# https://github.com/pandas-dev/pandas/blob/main/pandas/_libs/window/aggregations.pyx#L1837

with pd.option_context("display.float_format", "{:0.8f}".format):
    print("Test case 1")
    df = pd.DataFrame({"B": [50.0, 1.5, 1.1, 4.0, -3.0, 150.0, -400.0]})
    print(df.rolling(5).skew().to_string(index=False))
    print(df.rolling(5).apply(lambda x: pd.Series(x).skew()).to_string(index=False))

    print("Test case 2")
    df = pd.DataFrame({"B": [50.0, 1.5, 1.1, 4.0, -3.0, 150.0, -400.0]})
    print(df.rolling(3).skew().to_string(index=False))
    print(df.rolling(3).apply(lambda x: pd.Series(x).skew()).to_string(index=False))
    