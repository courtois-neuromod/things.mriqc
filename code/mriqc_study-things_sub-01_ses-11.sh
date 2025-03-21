#!/bin/bash
#SBATCH --account=rrg-pbellec
#SBATCH --job-name=mriqc_study-things_sub-01_ses-11.job
#SBATCH --output=./code/mriqc_study-things_sub-01_ses-11.out
#SBATCH --error=./code/mriqc_study-things_sub-01_ses-11.err
#SBATCH --time=2:00:00
#SBATCH --cpus-per-task=4
#SBATCH --mem-per-cpu=4G
#SBATCH --mail-type=BEGIN
#SBATCH --mail-type=END
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=basile.pinsard@gmail.com



export LOCAL_DATASET=$SLURM_TMPDIR/${SLURM_JOB_NAME//-/}/
flock --verbose /lustre03/project/rrg-pbellec/ria-beluga/alias/cneuromod.things.mriqc/.datalad_lock datalad clone ria+file:///lustre03/project/rrg-pbellec/ria-beluga#~cneuromod.things.mriqc $LOCAL_DATASET
cd $LOCAL_DATASET
git-annex enableremote ria-beluga-storage
datalad get -s ria-beluga-storage -J 4 -n -r -R1 . # get sourcedata/* containers
if [ -d sourcedata/smriprep ] ; then
    datalad get -n sourcedata/smriprep sourcedata/smriprep/sourcedata/freesurfer
fi
git submodule foreach --recursive git annex dead here
git submodule foreach git annex enableremote ria-beluga-storage
git checkout -b $SLURM_JOB_NAME

datalad containers-run -m 'mriqc_sub-01/ses-11' -n bids-mriqc --input sourcedata/things/sub-01/ses-11/fmap/ --input sourcedata/things/sub-01/ses-11/func/ --output . -- -w /tmp --participant-label 01 --session-id 11 --omp-nthreads 4 --nprocs 4 -m bold --mem_gb 16 --no-datalad-get  --no-sub sourcedata/things ./ participant 
mriqc_exitcode=$?

flock --verbose /lustre03/project/rrg-pbellec/ria-beluga/alias/cneuromod.things.mriqc/.datalad_lock datalad push -d ./ --to origin
exit $mriqc_exitcode 
