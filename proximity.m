function Proximity = proximity(extreme_type, Date, index0, start_th, end_th, REMO, MERG)
% PROXIMITY  (R2017 compatible)
% Calculate the proximity between adjacent events.
% extreme_type ∈ {'d','p','h','c'}:
%   d=drought, p=pluvial, h=heatwave, c=coldwave

% ---- make sure extreme_type is char ----
if isa(extreme_type,'string')
    extreme_type = char(extreme_type);
end

% ---- adjust sign for drought/coldwave ----
if ismember(extreme_type, {'d','c'})
    index    = -index0;
    start_th = -start_th;
elseif ismember(extreme_type, {'p','h'})
    index    = index0;
else
    index    = index0;
end

% ---- identify events ----
extreme_daily = PRM_extreme_identification(extreme_type, Date, index0, ...
                                           start_th, end_th, REMO, MERG);

maxID = max(extreme_daily(:,end));
Proximity = nan(maxID,1);

% ---- accumulate proximity ----
for i = 1:maxID
    aa = extreme_daily(:,end) == i;
    Proximity(i) = sum(start_th - index(aa,1));
end
end
