A = load_graph('four_clusters');
P = normout(A)';
x = gsqres_mex(P,1,1.e-3,1.,1);
sum(x)