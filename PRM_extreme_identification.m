function [idx] = PRM_extreme_identification(extreme_type, Date, index0, start_th, end_th, REMO, MERG)
% PRM_EXTREME_IDENTIFICATION  (R2017 compatible)
%
% output: idx: each column is [year, month, day, drought index,
%  dry/non-dry flag after pre-ID,
%  order after pre-ID,
%  flag after removal, order after removal,
%  flag after merging, order after merging]
%
% input:
%   Date  - [N x 3] [year month day]
%   index0 - drought index values
%   start_th, end_th - thresholds
%   REMO, MERG - remove & merge parameters (optional)

%% --- 0. Extreme type ---
% convert string to char for MATLAB 2017
if isa(extreme_type,'string')
    extreme_type = char(extreme_type);
end

if ismember(extreme_type, {'dr','cw','d','c'})
    index = -index0;
    start_th = -start_th;
    end_th   = -end_th;
elseif ismember(extreme_type, {'wet','hw','p','h'})
    index = index0;
else
    index = index0;
end

%% --- 1. Pre-identification ---
N = size(index,1);
idx = [Date, index, nan(N,1)];

for n = 1:N
    if n == 1
        if idx(n,4) >= start_th
            idx(n,5) = 1;
        else
            idx(n,5) = 0;
        end
    else
        if idx(n,4) >= start_th
            idx(n,5) = 1;
        elseif idx(n-1,5) == 1 && idx(n,4) > end_th
            idx(n,5) = 1;
        else
            idx(n,5) = 0;
        end
    end
end

idx(:,6) = nan(N,1);
aa = 0; bb = 0;

for n = 1:N
    if n == 1
        if idx(n,5) == 1
            idx(n,6) = bb;
        else
            idx(n,6) = aa;
        end
    else
        if idx(n,5) == 1 && idx(n-1,5) == 1
            idx(n,6) = bb;
        elseif idx(n,5) == 1 && idx(n-1,5) == 0
            bb = bb - 1;
            idx(n,6) = bb;
        elseif idx(n,5) == 0 && idx(n-1,5) == 1
            aa = aa + 1;
            idx(n,6) = aa;
        else
            idx(n,6) = aa;
        end
    end
end

%% --- 2. Remove minor periods ---
if nargin > 4
    idx(:,7) = zeros(N,1);
    dryOrders = unique(idx(:,6));
    dryOrders = dryOrders(dryOrders < 0);   % negative = dry
    for i = 1:numel(dryOrders)
        mask = idx(:,6) == dryOrders(i);
        if sum(mask) < REMO
            idx(mask,7) = 0;
        else
            idx(mask,7) = 1;
        end
    end

    idx(:,8) = nan(N,1);
    aa = 0; bb = 0;
    for n = 1:N
        if n == 1
            if idx(n,7) == 1
                idx(n,8) = bb;
            else
                idx(n,8) = aa;
            end
        else
            if idx(n,7) == 1 && idx(n-1,7) == 1
                idx(n,8) = bb;
            elseif idx(n,7) == 1 && idx(n-1,7) == 0
                bb = bb - 1;
                idx(n,8) = bb;
            elseif idx(n,7) == 0 && idx(n-1,7) == 1
                aa = aa + 1;
                idx(n,8) = aa;
            else
                idx(n,8) = aa;
            end
        end
    end

    %% --- 3. Merge near periods ---
    if nargin > 5
        idx(:,9) = idx(:,7);
        wetOrders = unique(idx(:,8));
        wetOrders = wetOrders(wetOrders > 0);   % positive = wet/non-dry
        for i = 1:numel(wetOrders)
            mask = idx(:,8) == wetOrders(i);
            if sum(start_th - idx(mask,4)) < MERG
                idx(mask,9) = 1;
            else
                idx(mask,9) = 0;
            end
        end

        idx(:,10) = nan(N,1);
        aa = 0; bb = 0;
        for n = 1:N
            if n == 1
                if idx(n,9) == 1
                    idx(n,10) = bb;
                else
                    idx(n,10) = aa;
                end
            else
                if idx(n,9) == 1 && idx(n-1,9) == 1
                    idx(n,10) = bb;
                elseif idx(n,9) == 1 && idx(n-1,9) == 0
                    bb = bb - 1;
                    idx(n,10) = bb;
                elseif idx(n,9) == 0 && idx(n-1,9) == 1
                    aa = aa + 1;
                    idx(n,10) = aa;
                else
                    idx(n,10) = aa;
                end
            end
        end
    end
end

%% --- 4. Restore original index values ---
idx(:,4) = index0;

end
