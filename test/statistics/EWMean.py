import pandas as pd

# https://github.com/pandas-dev/pandas/blob/main/pandas/_libs/window/aggregations.pyx#L1837

with pd.option_context("display.float_format", "{:0.8f}".format):
    print("Test case 1")
    df = pd.DataFrame({'B': [50.0, 1.5, 1.1, 4.0, -3.0, 150.0, -400.0]})
    print(df.ewm(alpha=0.9, adjust=False).mean().to_string(index=False)) 

    print("Test case 2")
    df = pd.DataFrame({'B': [50.0, 1.5, 1.1, 4.0, -3.0, 150.0, -400.0]})
    print(df.ewm(alpha=0.9, adjust=True).mean().to_string(index=False))  
