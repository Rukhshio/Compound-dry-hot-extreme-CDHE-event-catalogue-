# Compound-dry-hot-extreme-CDHE-event-catalogue-
This repository contains example MATLAB code (we have applied this to global dat at 0.1 resolution for create the CDHE event catalogue
)to extract compound dry–hot extreme (CDHE) events from a daily SSTCI time series using the Shan et al., 2024 removal–merging framework.

INPUTS
------
1) SSTCI.nc
   Required variables:
     - SSTCI(time,lat,lon) : daily SSTCI field
     - lat, lon            : coordinate vectors

2) Date.mat
   Required variable:
     - Date : datetime vector matching the SSTCI time axis

OUTPUT
------
CDHE_all.mat
  Variables saved in this file:
    1) CDHE  : nLat x nLon cell array
    2) lat   : latitude vector (length nLat)
    3) lon   : longitude vector (length nLon)

OUTPUT STRUCTURE 
----------------------------
CDHE is a cell array where each element corresponds to one grid cell:

  CDHE{i,j}  -> event catalogue for latitude index i and longitude index j

Mapping from indices to coordinates:
  latitude  = lat(i)
  longitude = lon(j)

Each CDHE{i,j} is either:
  - empty ([]) if no events are detected or the SSTCI series is invalid, OR
  - an event matrix with n rows by 10 columns (one row per event)

Each column represents one detected CDHE event, and columns store event attributes
1. seral Number	
2.Duration	
3.Severity	
4.Marginal Severity	
5.Start Year	
6.Start Month	
7.Start Day	
8.End Year	
9.End Month	
10.End Day

MAIN SCRIPT
-----------
calculate_CDHE_SSTCI.m

This script loops over all grid cells in SSTCI.nc and applies:
  - removal–merging threshold estimation
  - daily extreme identification
  - conversion from daily flags to event matrices

EVENT SETTINGS (as used in the script)
--------------------------------------

start_th_d   = -2 %used for extreme dry-hot which we used in our study it can be changed as required 
end_th_d     = -4

REQUIRED FUNCTIONS
------------------
The following Shan-method functions must be available on the MATLAB path:
  - remo_merg.m
  - PRM_extreme_identification.m
  - daily_2_events.m

HOW TO RUN
----------

1) Run in MATLAB:
     run('build_CDHE_from_SSTCI_nc_allgrid.m')

2) Output will be written as:
     CDHE_all.mat

NOTES
-----
- Missing values (NaNs) are handled by skipping grid cells with no valid SSTCI signal.
- The code is designed to work on any lat/lon grid provided in SSTCI.nc.
