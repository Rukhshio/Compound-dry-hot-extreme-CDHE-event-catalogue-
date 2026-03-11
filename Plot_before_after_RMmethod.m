%% plot_raw_SSTCI_vs_events_single_point.m
% Plot raw daily SSTCI and SSTCI during detected CDHE events for one grid cell.
%
% INPUTS:
%   - SSTCI.nc        : contains SSTCI(time,lat,lon), lat, lon
%   - CDHE_all.mat    : contains CDHE (cell array), lat, lon
%   - Date.mat    : contains Date (Nx3 [Y M D] or datetime vector)
%
% OUTPUT:
%   - Figure with two panels:
%       (a) raw SSTCI with threshold highlighting
%       (b) event-day SSTCI bars overlaid on raw SSTCI
%
% EVENT MATRIX COLUMNS (stored in each CDHE{i,j} cell):
%   1) Serial Number
%   2) Duration
%   3) Severity
%   4) Marginal Severity
%   5) Start Year
%   6) Start Month
%   7) Start Day
%   8) End Year
%   9) End Month
%  10) End Day

clear; clc;

%% --- User settings ---
sstci_nc  = 'SSTCI.nc';
cdhe_mat  = 'CDHE_all.mat';
date_file = 'Date.mat';

% Pick a target coordinate (nearest grid cell will be used)
lat_target = 28;
lon_target = 115;

% Plot year range (inclusive)
year_range = [2022 2022];

% Threshold for highlighting
start_th_c = -2;

%% --- Load Date and build datetime vector t ---
Sdate = load(date_file, 'Date');
Date = Sdate.Date;

if isdatetime(Date)
    t = Date(:);
else
    t = datetime(Date(:,1), Date(:,2), Date(:,3));
end

%% --- Load grid coordinates (from SSTCI.nc) ---
lat_nc = ncread(sstci_nc, 'lat');
lon_nc = ncread(sstci_nc, 'lon');

[~, lat_idx] = min(abs(lat_nc - lat_target));
[~, lon_idx] = min(abs(lon_nc - lon_target));

lat_sel = lat_nc(lat_idx);
lon_sel = lon_nc(lon_idx);

fprintf('Selected grid: lat=%.4f (idx=%d), lon=%.4f (idx=%d)\n', ...
        lat_sel, lat_idx, lon_sel, lon_idx);

%% --- Read SSTCI time series for this grid cell ---
SSTCI = squeeze(ncread(sstci_nc, 'SSTCI', [1, lat_idx, lon_idx], [Inf, 1, 1]));
SSTCI = SSTCI(:);

%% --- Load CDHE catalogue and extract events for this grid cell ---
Sc = load(cdhe_mat, 'CDHE');
CDHE_cell = Sc.CDHE{lat_idx, lon_idx};   % event matrix for this cell (or empty)

% Create an "event-day series" the same size as SSTCI (NaN outside events)
event_series = nan(size(SSTCI));

if ~isempty(CDHE_cell)
    % Column indices for start/end dates in the 10-column format
    c_sy = 5; c_sm = 6; c_sd = 7;
    c_ey = 8; c_em = 9; c_ed = 10;

    for e = 1:size(CDHE_cell,1)
        sdt = datetime(CDHE_cell(e,c_sy), CDHE_cell(e,c_sm), CDHE_cell(e,c_sd));
        edt = datetime(CDHE_cell(e,c_ey), CDHE_cell(e,c_em), CDHE_cell(e,c_ed));

        idx = (t >= sdt) & (t <= edt);
        event_series(idx) = SSTCI(idx);
    end
end

%% --- Select plotting window ---
start_idx = find(year(t) == year_range(1), 1, 'first');
end_idx   = find(year(t) == year_range(2), 1, 'last');
time_lim  = [t(start_idx), t(end_idx)];

%% --- Plot ---
figure('Position', [100, 500, 1600, 650]);

% (a) Raw SSTCI with threshold highlighting
subplot(2,1,1); hold on;

below = nan(size(SSTCI));
below(SSTCI < start_th_c) = SSTCI(SSTCI < start_th_c);

bar(t, below, 'EdgeColor', 'none', 'BarWidth', 1);
plot(t, SSTCI, '.-', 'LineWidth', 0.8);
yline(start_th_c, '--', 'LineWidth', 0.8);

xlim(time_lim);
ylabel('SSTCI', 'FontWeight', 'bold');
title('(a) Before', 'FontWeight', 'bold');
set(gca, 'xticklabel', [], 'FontWeight', 'bold');
grid on; box on; hold off;

% (b) Event-day SSTCI bars over raw series
subplot(2,1,2); hold on;

bar(t, event_series, 'EdgeColor', 'none', 'BarWidth', 1);
plot(t, SSTCI, '.-', 'LineWidth', 0.8);
yline(start_th_c, '--', 'LineWidth', 0.8);

xlim(time_lim);
ylabel('SSTCI', 'FontWeight', 'bold');
title('(b) After Removal-Merging Method appplied', 'FontWeight', 'bold');
set(gca, 'FontWeight', 'bold');
grid on; box on; hold off;

sgtitle(sprintf('Location: lat=%.2f, lon=%.2f', lat_sel, lon_sel), 'FontWeight', 'bold');