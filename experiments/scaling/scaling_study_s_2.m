%% study 2
prob = 0.48;
seq = [1,2,5];
minsize = 1000;
maxsize = 4e9/10; % should give about 2B non-zeros
ngraphs = 10;
scale = minsize;
sizes = [];
while scale <= maxsize
    sizes = [sizes scale*seq];
    scale = scale*10;
end
sizes(sizes > maxsize) = [];
ntrials = 20;
tol=1e-4;
%%
results = zeros(numel(sizes),ngraphs,ntrials);
gdata = struct;
for si = 1:numel(sizes);
    n = sizes(si); 
    for gi=1:ngraphs
        A = graph_model('forest-fire',n,'prob',prob,'initial',10);
        gdata(si,gi).n = n;
        gdata(si,gi).nnz = nnz(A);
        gdata(si,gi).maxdeg = full(max(sum(A,2)));
        startdeg = zeros(ntrials,1);
        for ti=1:ntrials
            p = randi([1,n]);
            startdeg(ti) = sum(A(:,p));
            t0=tic;
            [y npush] = gsqres_mex(A,p,tol,1.,0); 
            dt=toc(t0);
            results(si,gi,ti) = dt;
	    fprintf('Size = %10i  Graph = %2i  MaxDeg = %8i  StartDeg = %6i  Time = %.1f\n', n, gi, gdata(si,gi).maxdeg, startdeg(ti), dt);
        end
        gdata(si,gi).startdegs = startdeg;
        save 'scaling_s_multi.mat' results gdata
        clear A;
    end
end
