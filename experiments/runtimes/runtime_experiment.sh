#!/bin/bash

# to call this shell script, use this:
# ./runtime_experiment.sh
clear
echo Nexpokit runtime experiment

# change permissions to ensure this script can run everything it's supposed to
chmod 744 *.sh
chmod 744 *.m

echo 'Begin small dataset trials output in   runsmall\n'
nohup /p/matlab-7.14/bin/matlab -nodisplay -nodesktop -nojvm -nosplash -singleCompThread -r runtime_experiment > /scratch2/dgleich/kyle/joblog/runsmall.txt &

echo 'Begin twitter trials output in   runtwit\n'
nohup /p/matlab-7.14/bin/matlab -nodisplay -nodesktop -nojvm -nosplash -singleCompThread -r runtime_experiment_twitter > /scratch2/dgleich/kyle/joblog/runtwit.txt &

echo 'Begin friendster trials output in   runfri\n'
nohup /p/matlab-7.14/bin/matlab -nodisplay -nodesktop -nojvm -nosplash -singleCompThread -r runtime_experiment_friend > /scratch2/dgleich/kyle/joblog/runfri.txt &

echo 'Begin webbase trials output in   runweb\n'
nohup /p/matlab-7.14/bin/matlab -nodisplay -nodesktop -nojvm -nosplash -singleCompThread -r runtime_experiment_web > /scratch2/dgleich/kyle/joblog/runweb.txt &


echo 'finished calling all experiments\n'