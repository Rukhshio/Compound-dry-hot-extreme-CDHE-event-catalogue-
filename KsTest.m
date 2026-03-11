function [h, testResults] = KsTest(data, p, pd, Dn0, Dn0_level)
% KSTEST  (R2017 compatible)
% Test if data follow the given model distribution by Kolmogorov–Smirnov test
% at significance level p.
%
% data:  column vector(s)
% p:     significance level
% pd:    fitted distribution object
% Dn0:   table of critical values
% Dn0_level: vector of significance levels corresponding to columns of Dn0

N = size(data,2);
Dn = Dn0(:, Dn0_level == p);

h = nan(1,N);
testResults = cell(1,N);

for ii = 1:N
    % ---- remove NaNs ----
    x = data(:,ii);
    x(isnan(x)) = [];

    % ---- theoretical CDF ----
    xx     = sort(x);
    theop  = cdf(pd, xx);

    % ---- empirical CDF bounds ----
    n      = length(x);
    obspu  = (1:n) ./ n;       % upper
    obspl  = (0:n-1) ./ n;     % lower

    ks = max( max(abs(theop - obspu'), abs(theop - obspl')) );

    dn = Dn(n);
    if ks <= dn
        testResults{ii} = 'not rejected';
        h(ii) = 0;
    else
        testResults{ii} = 'rejected';
        h(ii) = 1;
    end
end
end
