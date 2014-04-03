experimentname = 'degruntime_friendster';

datalist = {'com-friendster'};
alglist = { 'expmv', 'half', 'gexpmq', 'gexpm', 'expmimv'};

addpath('~/nexpokit');


num_data = numel(datalist);
num_trials = 5;
num_algs = numel(alglist);

disp(experimentname);
maxnnz = 10000;
tol = 1e-4;
t = 1;

% LOAD PARAMETERS
%	this contains t, tol, maxnnz, num_trials
run('~/nexpokit/experiments/degruntimes/degruntime_parameters');

format shortg;

fprintf('\n Num of trials = %i \t Num datasets = %i \t tol = %5.8f \t maxnnz = %i \n\n', ...
		num_trials, num_data, tol, maxnnz);

heading = '\t ';
for alg_num = 1:num_algs,
	heading = strcat(heading, char(alglist(alg_num)), '\t\t ');
end

errdisplay = '\n err = ';
for alg_num = 1:num_algs,
	errdisplay = strcat( errdisplay, ' %f \t');
end
		
datasizes = zeros(num_data,1); % holds n for each graph
seeds = zeros(num_trials,num_data); % holds seeds for each trial for each graph
xtrues = sparse(1,num_trials*num_data);
time_vals = zeros(num_algs,num_trials,num_data);
err_vals = zeros(num_algs,num_trials,num_data);

P=1;

for dataindex = 1:num_data
	clear P;
	dataset = char(datalist(dataindex));
	load(strcat('/scratch2/dgleich/kyle/colstochdata/', dataset));
	datasizes(dataindex) = size(P,1);
	n = datasizes(dataindex);
	datasizes(dataindex) = size(P,1) + nnz(P);

	d = zeros(n,1);
	for i=1:n, d(i) = nnz(P(:,i)); end
	[degrees perm] = sort(d,'descend');	
	seeds(:,dataindex) = perm(whichnodes(1:num_trials)); % the seeds are the largest degree nodes
		
	if n > size(xtrues,1),
		xtrues(end:n,1)=0;
	end

	fprintf('\n\n Dataset = %s \t tol = %7.6f', dataset, tol);

	for trial=1:num_trials
		fprintf(strcat('\n T %i    ', heading), trial);	
		ind = seeds(trial,dataindex);
		ec = eyei(n,ind);

		alg_num = 1;
			tic; [x_true,s,m,mv,mvd] = expmv(t,P,ec,[],'single');
			time_vals(alg_num, trial, dataindex) = toc;
			normtrue = norm(x_true,1); %[vtrue strue] = sort(x_true, 'descend');
			xtrues(:,trial + num_trials*(dataindex-1)) = sparse(x_true);
			err_vals(alg_num, trial, dataindex) = 0.0;
			fprintf('\n time = %f', time_vals(alg_num, trial, dataindex));

		alg_num = alg_num + 1;
			tic; [y,s,m,mv,mvd] = expmv(t,P,ec,[],'half');
			time_vals(alg_num, trial, dataindex) = toc;
			err_vals(alg_num, trial, dataindex) = norm(x_true - y,1)/normtrue;
			fprintf('\t %f', time_vals(alg_num, trial, dataindex));

		alg_num = alg_num + 1;
			tic; [y npush] = gsqres_mex(P,ind,tol,t);
			time_vals(alg_num, trial, dataindex) = toc;
			err_vals(alg_num, trial, dataindex) = norm(x_true - y,1)/normtrue;
			fprintf('\t %f', time_vals(alg_num, trial, dataindex));
		
		alg_num = alg_num + 1;
	% don't comment out the alg_num increment -- that would mess up the dimension of time_vals, etc
%			tic; [y hpush hstep] = gexpm_hash_mex(P,ind,tol,t);
%			time_vals(alg_num, trial, dataindex) = toc;
%			err_vals(alg_num, trial, dataindex) = norm(x_true - y,1)/normtrue;
%			fprintf('\t %f', time_vals(alg_num, trial, dataindex));
			fprintf('\t');
			
		alg_num = alg_num + 1;
			tic; [y svpush] = expm_svec_mex(P,ind,tol,t,maxnnz);
			time_vals(alg_num, trial, dataindex) = toc;
			err_vals(alg_num, trial, dataindex) = norm(x_true - y,1)/normtrue;
			fprintf('\t %f', time_vals(alg_num, trial, dataindex));

		fprintf(errdisplay, err_vals(1:num_algs,trial,dataindex) );
%		fprintf('\n err = '); disp(	err_vals(1:num_algs,trial,dataindex)' );

	end % end trials for that dataset
	
		aveerrors = sum(err_vals(:,:,dataindex)')/num_trials;
		avetimes = sum(time_vals(:,:,dataindex)')/num_trials;
	fprintf(strcat('\n\n',heading));
	fprintf('\n ave times'); disp(avetimes);
	fprintf(' ave error'); disp(aveerrors);

end % end datasets

save(['/scratch2/dgleich/kyle/nexpokit/' experimentname '_expmv_vectors' '.mat'], 'xtrues', 'seeds', '-v7.3');
save(['/scratch2/dgleich/kyle/nexpokit/results/' experimentname '.mat'], 'seeds', 'err_vals', 'time_vals', ...
		'datasizes', '-v7.3');
		
exit