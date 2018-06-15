#!/bin/bash

#
#  LAUNCH SPECIFIED NUMBER OF JOBS TO SLURM
#

if [ $# -eq 0 ] ; then
    echo "USAGE:" "<SUPERTASK> <NUM_OF_TASKS>"
    exit
fi

SUPERTASK=$1
NUM_TO_RUN=$2
ALL_TASKS="$SUPERTASK"/ALL_TASKS
TODO_TASKS="$SUPERTASK"/TODO_TASKS
NOW_RUNNING="$SUPERTASK"/RUNNING_TASKS
# Dynamic var to track remaning runs to launch
runs_to_launch=$NUM_TO_RUN

LAUNCHED_JOBS="$SUPERTASK"/"launched_jobs.dat"

# For script in TODO_TASKS/*.sbc
for TASK in "$TODO_TASKS"/*; do
        if [ $NUM_TO_RUN -lt 1 ]; then
            # Stop the execution once all required scripts are launched;
            break
        fi
        echo "LAUNCHING >> $(basename $TASK) "
        # ADD JOB NAME TO RUNNING LOG
        echo -n "$(basename $TASK) " >> $LAUNCHED_JOBS
        # *** EXECUTE THE SCRIPT ON SLURM ***
        # ADD LAUNCH MESSAGE TO THE LOG
        sbatch $TASK >> $LAUNCHED_JOBS
        # COPY FILE TO CURRENTLY RUNNING FOLDER
        cp "$TASK" "$NOW_RUNNING"
        # Decrement the counter upon each run
        NUM_TO_RUN=`expr $NUM_TO_RUN - 1`
done