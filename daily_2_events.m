function events = daily_2_events(extreme_daily, extreme_type)
% DAILY_2_EVENTS  (R2017 compatible)
% Convert daily index table to event statistics.
%
% events = [num, duration, severity, intensity,
%           gap_len, inter_arrival,
%           start_y, start_m, start_d,
%           end_y,   end_m,   end_d,
%           mid_year]

% --- ensure extreme_type is char for old MATLAB ---
if nargin < 2
    extreme_type = '';
elseif isa(extreme_type,'string')
    extreme_type = char(extreme_type);
end

% ---- basic size checks ----
if isempty(extreme_daily)
    events = [];
    return
end

% number of events (negative IDs)
numEvents = -nanmin(extreme_daily(:,end));
events = nan(numEvents,13);

for i = 1:numEvents
    aa = extreme_daily(extreme_daily(:,end) == -i, :);

    % num, duration, severity, intensity
    events(i,1:4) = [i, size(aa,1), sum(aa(:,4)), sum(aa(:,4))/size(aa,1)];

    % start/end dates
    events(i,7:12) = [aa(1,1:3), aa(end,1:3)];

    % middle year (year with max #days for this event)
    if aa(1,1) == aa(end,1)
        events(i,13) = aa(end,1);
    else
        yrs = aa(1,1):aa(end,1);
        cnt = zeros(size(yrs));
        for k = 1:numel(yrs)
            cnt(k) = sum(extreme_daily(:,1) == yrs(k) & ...
                         extreme_daily(:,end) == -i);
        end
        [~,idx] = max(cnt);
        events(i,13) = yrs(idx);
    end

    % gap and inter-arrival
    if i < 2
        events(i,5:6) = nan;
    else
        bb = find(extreme_daily(:,end) == -i);
        cc = find(extreme_daily(:,end) == -(i-1));
        events(i,5) = bb(1) - cc(end) - 1;   % gap
        events(i,6) = events(i,2) + events(i,5);
    end
end

% ---- sign for drought/coldwave ----
if ismember(extreme_type, {'d','c'})
    events(:,3:4) = -events(:,3:4);
end
end
