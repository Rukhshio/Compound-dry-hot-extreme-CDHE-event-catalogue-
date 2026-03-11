%% build_CDHE_from_SSTCI_nc_allgrid.m
% Build CDHE event catalogue for ALL grid cells from SSTCI.nc using Shan
% removal–merging workflow, and save as one MAT file.
%
% INPUTS:
%   - SSTCI.nc      : contains SSTCI(time,lat,lon) and coordinates lat, lon
%   - date_file     : MAT file containing variable "Date" (datetime vector)
%
% OUTPUT (MAT):
%   CDHE_all.mat containing:
%     CDHE : nLat x nLon cell array
%            each cell contains an event matrix (n x 10) or is empty

%     lat  : latitude vector
%     lon  : longitude vector
%
% EVENT MATRIX FORMAT:
% matrix becomes n x 10 (the 10 column represent following)
%1.seral Number 2.Duration	3.Severity 4.Marginal Severity	5.Start Year 6.Start Month	7.Start Day	8.End Year	9.End Month	10.End Day
% REQUIREMENTS (functions must be on MATLAB path):
%   remo_merg.m
%   PRM_extreme_identification.m
%   daily_2_events.m
%
% EVENT PARAMETERS (same as your workflow):
%   scale_p         = 3
%   start_th_d      = -2
%   end_th_d        = -4
%   p               = 0.05
%   ev_num_ctrl     = 0.1
%   ev_days_ctrl    = 120

clear; clc;

%% === SETTINGS ===
sstci_nc  = 'SSTCI.nc';

date_file = 'Date.mat';   % must contain variable "Date"
out_file  = 'CDHE_all.mat';

% Event settings (unchanged)
scale_p      = 3;
start_th_d   = -2;
end_th_d     = -4;
p            = 0.05;
ev_num_ctrl  = 0.1;
ev_days_ctrl = 120;

% Columns to remove from the original n x 13 event matrix
cols_to_remove = [5 6 13]; %cleaning data 

%% === LOAD DATE VECTOR (REQUIRED) ===
Sdate = load(date_file, 'Date');
if ~isfield(Sdate, 'Date')
    error('Date file does not contain variable "Date": %s', date_file);
end
Date = Sdate.Date;

%% === READ COORDINATES ===
lat = ncread(sstci_nc, 'lat');
lon = ncread(sstci_nc, 'lon');

nLat = numel(lat);
nLon = numel(lon);

%% === INITIALIZE OUTPUT CELL ARRAY ===
CDHE = cell(nLat, nLon);

%% === MAIN LOOP OVER LATITUDES ===
for lat_idx = 1:nLat
    try
        % Read SSTCI for this latitude as (time x lon)
        SPI = squeeze(ncread(sstci_nc, 'SSTCI', [1, lat_idx, 1], [Inf, 1, Inf]));
        if size(SPI,2) ~= nLon
            SPI = SPI'; % ensure (time x lon)
        end

        valid_cols = find(any(~isnan(SPI), 1));
        nValid = numel(valid_cols);
        results = cell(1, nValid);

        % Parallel loop over valid longitudes
        parfor k = 1:nValid
            j = valid_cols(k);
            spi_column = SPI(:, j);
            tmp = [];

            try
                cc = remo_merg('c', Date, spi_column, ...
                               scale_p, p, start_th_d, end_th_d, ...
                               ev_num_ctrl, ev_days_ctrl);

                removal_th = cc(1);
                merging_th = cc(2);

                daily_idx = PRM_extreme_identification('c', Date, spi_column, ...
                                                       start_th_d, end_th_d, ...
                                                       removal_th, merging_th);

                tmp = daily_2_events(daily_idx, 'c');  % expected n x 13

                % Remove columns 5, 6, and 13 -> store as n x 10
                if ~isempty(tmp)
                    if size(tmp,2) == 13
                        tmp(:, cols_to_remove) = [];
                    end
                end

            catch
                tmp = [];
            end

            results{k} = tmp;
        end

        % Store results into full grid
        for kk = 1:nValid
            j = valid_cols(kk);
            CDHE{lat_idx, j} = results{kk};
        end

        if lat_idx==1 || mod(lat_idx,5)==0
            fprintf('Processed %d/%d latitudes\n', lat_idx, nLat);
        end

    catch ME_outer
        warning('Latitude index %d failed: %s', lat_idx, ME_outer.message);
    end
end

%% === SAVE OUTPUT ===
save(out_file, 'CDHE', 'lat', 'lon', '-v7.3');
fprintf('Saved full CDHE catalogue to: %s\n', out_file);