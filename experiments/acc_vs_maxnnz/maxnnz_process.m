%% FIRST COMBINE DATA FROM small, web, twit, friendster
experimentname = 'acc_maxnnz';
experiment_directory = '/scratch2/dgleich/kyle/nexpokit/results/';


load(strcat(experiment_directory, experimentname));
               
% [intersect,kendall]_vals is (4,50,7,3) = (dataset, trial, maxnnzs, topks)
% get dimensions of data
[num_data, num_trials, num_maxnnzs, num_topks] = size(kendall_vals);
num_metrics = 3; %for each form of accuracy we might use: 1-norm, kendall, intersect

% take median from each set of 50 trials
acc_data = zeros(num_metrics, num_data, num_maxnnzs, num_topks);

for dataid=1:num_data
	for maxnnzsid=1:num_maxnnzs
		for topksid=1:num_topks
			acc_data(1,dataid,maxnnzsid,topksid) = log10(prctile(err_vals(maxnnzsid,:,dataid),50));
			acc_data(2,dataid,maxnnzsid,topksid) = prctile(kendall_valsnn(dataid, :, maxnnzsid, topksid),50);
			acc_data(3,dataid,maxnnzsid,topksid) = prctile(intersect_valsnn(dataid, :, maxnnzsid, topksid),50);
		end
	end
end
edgeden = edgedensity;

numrecords = num_data;

  % now load webbase
  	load(strcat(experiment_directory , experimentname, '_webbase'));
  	num_newdata = size(degrees,2);
  	acc_data(:,end:end+num_newdata,:,:) = 0; % make room in the data-log for new data
	for dataid=1:num_newdata
		for maxnnzsid=1:num_maxnnzs
			for topksid=1:num_topks
				acc_data(1,dataid,maxnnzsid,topksid) = log10(prctile(err_vals(maxnnzsid,:,dataid),50));
				acc_data(2,dataid,maxnnzsid,topksid) = prctile(kendall_valsnn(dataid, :, maxnnzsid, topksid),50);
				acc_data(3,dataid,maxnnzsid,topksid) = prctile(intersect_valsnn(dataid, :, maxnnzsid, topksid),50);
			end
		end
	end
	edgeden(end:end+num_newdata) = edgedensity;
	
  	numrecords = numrecords + num_newdata;
	
  	
  % now load twitter
  	load(strcat(experiment_directory , experimentname, '_twitter'));
  	num_newdata = size(degrees,2);
  	acc_data(:,end:end+num_newdata,:,:) = 0; % make room in the data-log for new data
	for dataid=1:num_newdata
		for maxnnzsid=1:num_maxnnzs
			for topksid=1:num_topks
				acc_data(1,dataid,maxnnzsid,topksid) = log10(prctile(err_vals(maxnnzsid,:,dataid),50));
				acc_data(2,dataid,maxnnzsid,topksid) = prctile(kendall_valsnn(dataid, :, maxnnzsid, topksid),50);
				acc_data(3,dataid,maxnnzsid,topksid) = prctile(intersect_valsnn(dataid, :, maxnnzsid, topksid),50);
			end
		end
	end
	edgeden(end:end+num_newdata) = edgedensity;
		
  	numrecords = numrecords + num_newdata;
  
  % now load friendster
  	load(strcat(experiment_directory , experimentname, '_friend'));
  	num_newdata = size(degrees,2);
  	acc_data(:,end:end+num_newdata,:,:) = 0; % make room in the data-log for new data
	for dataid=1:num_newdata
		for maxnnzsid=1:num_maxnnzs
			for topksid=1:num_topks
				acc_data(1,dataid,maxnnzsid,topksid) = log10(prctile(err_vals(maxnnzsid,:,dataid),50));
				acc_data(2,dataid,maxnnzsid,topksid) = prctile(kendall_valsnn(dataid, :, maxnnzsid, topksid),50);
				acc_data(3,dataid,maxnnzsid,topksid) = prctile(intersect_valsnn(dataid, :, maxnnzsid, topksid),50);
			end
		end
	end
	edgeden(end:end+num_newdata) = edgedensity;
		
  	numrecords = numrecords + num_newdata;
	clear edgedensity;
	edgedensity = edgeden;
	
% Now acc_maxnnz contains all data for maxnnz experiments

save(strcat(experiment_directory, experimentname, '_to_plot', '.mat'), 'acc_data', 'edgedensity','-v7.3');
exit