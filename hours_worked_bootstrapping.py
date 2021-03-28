import scipy.stats as stat# perform normality test
import re    # for regular expressions 
import nltk  # for text manipulation 
import string 
import warnings 
import numpy as np 
import pandas as pd 
import seaborn as sns 
import matplotlib.pyplot as plt  

pd.set_option("display.max_colwidth", 200) 
warnings.filterwarnings("ignore", category=DeprecationWarning) 

%matplotlib inline

x = pd.read_csv('/Users/allison/Documents/shifts_worked.csv') 

#bootstrapping to test if there is a difference between how many hours two groups of users work. 

#control and exp groups creation
control= x[x['state']== "ELIGIBLE_NOT_ENROLLED"]
control = control['hrs_worked']
exp= x[x['state']== "ACTIVE"]
exp = exp['hrs_worked']

import scipy.stats as stat
# perform normality test
print(stat.normaltest(control))
print(stat.normaltest(exp))

sns.distplot(control)
sns.distplot(exp)

# create function to sample with replacement
def get_sample(df, n):
    sample = []
    while len(sample) != n:
        x = np.random.choice(df)
        sample.append(x)
    return sample# create function to calculate mean of the sample
def get_sample_mean(sample):
    return sum(sample)/len(sample)# combine functions to create a sample distribution
    
# create a distribution size of 1000 and sample size of 500
def create_sample_distribution(df, dist_size=1000, n=500):
    sample_dist = [] 
    while len(sample_dist) != dist_size:
        sample = get_sample(df, n)
        sample_mean = get_sample_mean(sample)
        sample_dist.append(sample_mean)
    return sample_dist# create sample distributions of sample mean for control and target
    
ctrl_sample = create_sample_distribution(control)
exp_sample = create_sample_distribution(exp)

sns.distplot(ctrl_sample)
sns.distplot(exp_sample)
