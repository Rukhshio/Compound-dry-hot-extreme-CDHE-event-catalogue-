function [ind, nse, models, criteria_gev, ksTest_best_dist] = best_fitting(data, for_plot, for_ks, for_criteria)
% BEST_FITTING  (R2017 compatible)
% Find the best distribution for DATA using AIC / BIC / RMSD / NSE (and optional KS).

% ---------------- Defaults for old MATLAB ----------------
if nargin < 2 || isempty(for_plot),    for_plot    = '';    end
if nargin < 3 || isempty(for_ks),      for_ks      = false; end
if nargin < 4 || isempty(for_criteria),for_criteria= {'AIC','RMSD'}; end

% if string scalar(s) supplied, convert to char/cell
if isa(for_plot,'string');     for_plot    = char(for_plot); end
if isa(for_criteria,'string'); for_criteria= cellstr(for_criteria); end

load Dn0.mat

% ---- distributions to test ----
models = {'Normal','Exponential','Gamma','gev','InverseGaussian', ...
          'logistic','Loglogistic','Lognormal','Burr','NOBEST'};
k = [2 1 2 3 2 2 2 2 3];    % number of parameters

N = numel(models);
MLE  = nan(N,1);
NSE  = nan(N,1);
AIC  = nan(N,1);
BIC  = nan(N,1);
RMSD = nan(N,1);
h_ks = nan(N,1);

for i = 1:N-1
    try
        lastwarn('','');
        pd = fitdist(data, models{i});     % fit distribution

        [~,warnId] = lastwarn;
        if isempty(warnId)
            % log-likelihood, ICs
            MLE(i) = -negloglik(pd);
            AIC(i) = 2*k(i) - 2*MLE(i);
            BIC(i) = k(i)*log(length(data)) - 2*MLE(i);

            % empirical vs fitted CDF for RMSD & NSE
            [Femp, Xemp] = ecdf(data);
            Ffit = icdf(pd, Femp);
            Xemp  = Xemp(2:end-1);
            Ffit  = Ffit(2:end-1);

            delta = Xemp - Ffit;
            RMSD(i) = sqrt(sum(delta.^2)/length(Ffit));
            NSE(i)  = 1 - sum(delta.^2) / sum((Ffit-mean(Ffit)).^2);

            % plotting
            if isequal(for_plot,'p')
                xs  = linspace(min(data), max(data), 100)';
                cdfFit = cdf(pd,xs);
                figure(i)
                stairs(Xemp, Femp(2:end-1),'o-'); hold on
                plot(xs,cdfFit,'LineWidth',1.5);
                xlabel('Variable'); ylabel('Cumulative probability');
                title(['Log-likelihood: ', num2str(MLE(i),4)]);
                legend({'Empirical CDF', [models{i} ' CDF']}, 'Location','southeast');
                grid on; hold off
            end
        end
    catch
        % skip this distribution on error
    end
end

% ---- choose best by criteria ----
NN = numel(for_criteria);
IND = nan(NN,1);
for j = 1:NN
    crit = for_criteria{j};
    switch crit
        case 'AIC'
            [~,IND(j)] = nanmin(AIC);
        case 'BIC'
            [~,IND(j)] = nanmin(BIC);
        case 'MLE'
            [~,IND(j)] = nanmax(MLE);
        case 'RMSD'
            [~,IND(j)] = nanmin(RMSD);
    end
end

if numel(unique(IND(~isnan(IND)))) == 1
    ind = IND(1);
else
    ind = N;    % “NOBEST”
end

% --- KS flag for best ---
txt = {'not rejected','rejected'};
if ind <= length(h_ks) && ~isnan(h_ks(ind))
    ksTest_best_dist = txt{h_ks(ind)+1};
else
    ksTest_best_dist = 'nan';
end

nse = NSE(ind);
criteria_gev = [MLE(4), AIC(4), BIC(4), NSE(4)];

end
