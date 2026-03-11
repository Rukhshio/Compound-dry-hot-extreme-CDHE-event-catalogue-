function [best_dist, h] = meet_two_assumption_or_not(extreme_type, extreme_daily, criteria, p, Dn0, Dn0_level)
% MEET_TWO_ASSUMPTION_OR_NOT (R2017 compatible)

M = -min(extreme_daily(:,end));
events = nan(M,5);

for i = 1:M
    aa = extreme_daily(extreme_daily(:,end) == -i, :);
    events(i,1:4) = [i, size(aa,1), sum(aa(:,4)), sum(aa(:,4))/size(aa,1)]; % num, duration, severity, intensity
    if i < 2
        events(i,5) = nan;
    else
        bb = find(extreme_daily(:,end) == -i);
        cc = find(extreme_daily(:,end) == -(i-1));
        events(i,5) = bb(1) - cc(end) - 1;   % duration of the non-dry period
    end
end

arrivals_spells = events(2:end,2) + events(2:end,5);

% ---- sign for drought-like types ----
if ismember(extreme_type, {'d','c'})
    events(:,3:4) = -events(:,3:4);
end

% ===== Assumption 1: inter-arrival times ~ exponential =====
pd = fitdist(arrivals_spells,'exp');
h  = KsTest(arrivals_spells, p, pd, Dn0, Dn0_level);   % h==0 means no rejection

best_dist = 'nan';
if h == 0
    % ===== Assumption 2: severity ~ GEV =====
    pd2 = fitdist(events(:,3),'gev');
    h2  = KsTest(events(:,3), p, pd2, Dn0, Dn0_level);
    if h2 == 0
        % choose best distribution (AIC/RMSD)
        [ind, ~, models] = best_fitting(events(:,3), '', true, criteria);
        % make sure we always return a char, not a string
        if iscell(models)
            best_dist = models{ind};
        else
            best_dist = models(ind);
        end
    end
end
end
