%matplotlib inline
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import datetime
from dateutil.relativedelta import relativedelta
import seaborn as sns
import statsmodels.api as sm  
from statsmodels.tsa.stattools import acf  
from statsmodels.tsa.stattools import pacf
from statsmodels.tsa.seasonal import seasonal_decompose

df = pd.read_csv('dataset')
df.head()
plt.xlabel('Date')
plt.ylabel('Percent Retained')
plt.plot(df)

decomposition = seasonal_decompose(df.percent_retained_30, freq=4)  
fig = plt.figure()  
fig = decomposition.plot()  
fig.set_size_inches(15, 8)

trend = decomposition.trend
seasonal = decomposition.seasonal 
residual = decomposition.resid

from statsmodels.tsa.stattools import adfuller
def test_stationarity(timeseries):

    #Determing rolling statistics
    rolmean = timeseries.rolling(4).mean()
    rolstd = timeseries.rolling(4).std()

    #Plot rolling statistics:
    fig = plt.figure(figsize=(12, 8))
    orig = plt.plot(timeseries, color='blue',label='Original')
    mean = plt.plot(rolmean, color='red', label='Rolling Mean')
    std = plt.plot(rolstd, color='black', label = 'Rolling Std')
    plt.legend(loc='best')
    plt.title('Rolling Mean & Standard Deviation')
    plt.show()
    
    #Perform Dickey-Fuller test:
    print('Results of Dickey-Fuller Test:')
    dftest = adfuller(timeseries, autolag='AIC')
    dfoutput = pd.Series(dftest[0:4], index=['Test Statistic','p-value','#Lags Used','Number of Observations Used'])
    for key,value in dftest[4].items():
        dfoutput['Critical Value (%s)'%key] = value
    print(dfoutput)
    
#is data stationary
test_stationarity(df.percent_retained_30)

#make stationary
df['first_difference'] = df.percent_retained_30 - df.percent_retained_30.shift(1)
test_stationarity(df.first_difference.dropna(inplace=False))


#take seasonal difference to remove seasonality
#not an improvement

df['seasonal_difference'] = df.percent_retained_30 - df.percent_retained_30.shift(4)
test_stationarity(df.seasonal_difference.dropna(inplace=False))

#make removed seasonality data stationary
df['seasonal_first_difference'] = df.first_difference - df.first_difference.shift(4)
test_stationarity(df.seasonal_first_difference.dropna(inplace=False))

df['forecast'] = results.predict(start = 20, end= 50, dynamic= True)  
df[['percent_retained_30', 'forecast']].plot(figsize=(12, 8))

start = datetime.datetime.strptime("2018-09-01", "%Y-%m-%d")
date_list = [start + relativedelta(months=x) for x in range(0,12)]
future = pd.DataFrame(index=date_list, columns= df.columns)
df = pd.concat([df, future])

start_index = len(trend)
end_index = len(trend)

#df['forecast'] = results.predict(start = 19, end = 200, dynamic= True)  
df['forecast'] = results.predict(start = 19, end = 40, dynamic= True)  
df[['percent_retained_30', 'forecast']].ix[-24:].plot(figsize=(12, 8)) 

print(df)

df.to_csv("dataset")
