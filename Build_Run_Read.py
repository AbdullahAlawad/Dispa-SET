import os
import sys
import numpy as np
import pandas as pd
import datetime as dt
from dispaset.postprocessing import postprocessing as post
import importlib
importlib.reload(post)
import dispaset as ds
import matplotlib.pyplot as plt
from matplotlib.pyplot import *
import seaborn as sns
import matplotlib.dates as mdates
import pickle
import time as tm
import logging
import shutil
import json


shutil.copy('input_data/ConfigGCC2.xlsx', 'Simulations/ConfigGCC2.xlsx')


# Load the configuration file
config = ds.load_config_excel('Simulations/ConfigGCC2.xlsx')

# Build the simulation environment:
SimData, FuelPrices, FuelPrices2 = ds.build_simulation(config, LocalSubsidyMultiplier=1, ExportCostMultiplier=1)


r = ds.solve_GAMS(config['SimulationDirectory'], config['GAMS_folder'])


path = 'Simulations/simulation_GCC'
inputs,results = ds.get_sim_results(path=path,cache=True)


with open('output_data/results.json', 'w') as fp:
    json.dump(str(results), fp)