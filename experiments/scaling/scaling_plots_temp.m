addpath('../plotting_utils'); % so "set_figure_size.m" is available
%%
load temp_results
results = results(:,1:30);
%%
gdata = gdata';
%%
maxd = full([gdata.maxdeg]);
ns = [gdata.n];
nnzs = [gdata.nnz];
means = mean(results,3)';

semilogx(maxd,means(1:numel(maxd)),'.')
%%
loglog(maxd.^2,means(1:numel(maxd)),'.')
%%
loglog(ns,means(1:numel(maxd)),'.')
%%
semilogx(ns,means(1:numel(maxd))./(maxd.^2.*log(maxd.^2)))
%%
semilogx(ns,mean(results'))
%%
loglog(maxd.*log(maxd).^(3/2),(mean(results'))./maxd)