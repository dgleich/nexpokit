
%% fix the data
load scaling_1
results = results(1:17,:)';
maxd = full([gdata.maxdeg]);
maxd2 = maxd.^2;
ns = [gdata.n];
nnzs = [gdata.nnz];
gsize = ns+nnzs;
p10 = prctile(results,10);
p25 = prctile(results,25);
p75 = prctile(results,75);
p50 = prctile(results,50);
p90 = prctile(results,90);
%%
clf; hold on;
%patch([gsize fliplr(gsize)],[p10 fliplr(p90)],[0.8,1,0.8]);
%patch([gsize fliplr(gsize)],[p25 fliplr(p75)],[0.5,1,0.5]);
patch([gsize fliplr(gsize)],[p25 fliplr(p75)],[0.7,1,0.7]);

set(gca,'XScale','log');
set(gca,'YScale','log');
plot(gsize,p50,'.-','MarkerSize',18,'LineWidth',2,'Color',[0,0,0.8]);
xlim([min(gsize),max(gsize)]);
set(gca,'XTick',[1e4,1e6,1e8]);
ylabel('time in seconds');
xlabel('graph size');
set_figure_size([3,3]);
print(gcf,'ff-040-runtime.eps','-depsc2');

%%
load scaling_s
results = results(1:15,:)';
gdata = gdata(1:15);
maxd = full([gdata.maxdeg]);
maxd2 = maxd.^2;
ns = [gdata.n];
nnzs = [gdata.nnz];
gsize = ns+nnzs;
p10 = prctile(results,10);
p25 = prctile(results,25);
p75 = prctile(results,75);
p50 = prctile(results,50);
p90 = prctile(results,90);

%%

clf; hold on;
%patch([gsize fliplr(gsize)],[p10 fliplr(p90)],[0.8,1,0.8]);
patch([gsize fliplr(gsize)],[p25 fliplr(p75)],[0.7,1,0.7]);

set(gca,'XScale','log');
set(gca,'YScale','log');
plot(gsize,p50,'.-','MarkerSize',18,'LineWidth',2,'Color',[0.0,0,0.8]);
xlim([min(gsize),max(gsize)]);
ylabel('time in seconds');
xlabel('graph size');
set(gca,'XTick',[1e4,1e6,1e8]);
set_figure_size([3,3]);
print(gcf,'ff-048-runtime.eps','-depsc2');

%%
clf; hold on;
patch([maxd2 fliplr(maxd2)],[p25 fliplr(p75)],[0.7,1,0.7]);

set(gca,'XScale','log');
set(gca,'YScale','log');
plot(maxd2,p50,'.-','MarkerSize',18,'LineWidth',2,'Color',[0.0,0,0.8]);
xlim([min(maxd2),max(maxd2)]);
ylabel('time in seconds');
xlabel('graph size');
set(gca,'XTick',[1e4,1e6,1e8]);
set_figure_size([3,3]);

ylabel('time in seconds');
xlabel('max-degree squared');
line([1e3,1e9],[1e-4,1e2]);

print(gcf,'ff-048-scaling-d2.eps','-depsc2');

%% 
load scaling_s_multi
gdata = gdata';
results = permute(results,[2,1,3]);
maxd = full([gdata.maxdeg]);
maxd2 = maxd.^2;
maxd2log = maxd.^2.*log(maxd.^2);
ns = [gdata.n];
nnzs = [gdata.nnz];
gsize = ns+nnzs;
p10 = prctile(results,10,3);
p25 = prctile(results,25,3);
p75 = prctile(results,75,3);
p50 = prctile(results,50,3);
p90 = prctile(results,90,3);
pmean = mean(results,3);

%%
x = mean(results,3);
plot(nnzs,x(:),'.');

%%
clf; hold on;
%patch([gsize fliplr(gsize)],[p10 fliplr(p90)],[0.8,1,0.8]);
[~,perm] = sort(gsize);
plower = p25(:)';
pupper = p75(:)';
pmid = p50(:)';

patch([gsize(perm) fliplr(gsize(perm))],[plower(perm) fliplr(pupper(perm))],[0.7,1,0.7]);

set(gca,'XScale','log');
set(gca,'YScale','log');
plot(gsize,pmid(perm),'.-','MarkerSize',18,'LineWidth',2,'Color',[0.0,0,0.8]);
xlim([min(gsize),max(gsize)]);
ylabel('time in seconds');
xlabel('graph size');
axis square;
line([1e3,1e9],[1e-4,1e2]);
set(gca,'XTick',[1e4,1e6,1e8]);
set_figure_size([3,3]);

%%
clf; hold on;
[~,perm] = sort(maxd2);
plower = p25(:)';
pupper = p75(:)';
pmid = p50(:)';

%patch([maxd2(perm) fliplr(maxd2(perm))],[plower(perm) fliplr(pupper(perm))],[0.7,1,0.7]);

set(gca,'XScale','log');
set(gca,'YScale','log');
plot(maxd2,pmid(perm),'.','MarkerSize',18,'LineWidth',2,'Color',[0.0,0,0.8]);
xlim([min(maxd2),max(maxd2)]);
ylabel('time in seconds');
xlabel('max-degree squared');
line([1e3,1e9],[1e-4,1e2]);
axis square;
set(gca,'XTick',[1e4,1e6,1e8]);
set_figure_size([3,3]);

%%
clf; hold on;
[~,perm] = sort(maxd2log);
plower = p25(:)';
pupper = p75(:)';
pmid = pmean(:)';

%patch([maxd2(perm) fliplr(maxd2(perm))],[plower(perm) fliplr(pupper(perm))],[0.7,1,0.7]);

set(gca,'XScale','log');
set(gca,'YScale','log');
plot(maxd2log,pmid(perm),'.','MarkerSize',18,'LineWidth',2,'Color',[0.0,0,0.8]);
xlim([min(maxd2log),max(maxd2log)]);
ylabel('time in seconds');
xlabel('max-degree squared');
line([1e3,1e9],[1e-4,1e2]);
axis square;
set(gca,'XTick',[1e4,1e6,1e8]);
set_figure_size([3,3]);