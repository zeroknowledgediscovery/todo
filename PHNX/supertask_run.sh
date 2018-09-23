#!/bin/bash

# ITERATIVE RUN OF THE SUPERTASK

#># import helper functions
source ./toolbox.sh

USAGE='basename <SUPERTASK> <USER> <MAX_PARALLEL_JOBS>'

SUPERTASKFOLDER=$1 
USER=$2
MAX_PARALLEL_JOBS=$3

ALL_TASKS="$SUPERTASKFOLDER"/ALL_TASKS
TODO_TASKS="$SUPERTASKFOLDER"/TODO_TASKS
RUNNING_TASKS="$SUPERTASKFOLDER"/RUNNING_TASKS
ERR_TASKS="$SUPERTASKFOLDER"/ERR_TASKS
DONE_TASKS="$SUPERTASKFOLDER"/DONE_TASKS
ERROR_LOG="$SUPERTASKFOLDER"/phnx.err
STATS="$SUPERTASKFOLDER"/STATS
LAUNCHED_JOBS="$SUPERTASKFOLDER"/"launched_jobs.dat"
RUNNING_IDS="$SUPERTASKFOLDER"/"running_ids.dat"
ERRED_IDS="$SUPERTASKFOLDER"/"erred_ids.dat"
BUFFER="$SUPERTASKFOLDER"/"buffer.dat"

touch $LAUNCHED_JOBS
touch $RUNNING_IDS
touch $ERRED_IDS
touch $BUFFER

######################################################
#   UPDATE CURRENTLY RUNNING, DONE AND ERRED TASKS   #
######################################################

# READ CURRENTLY RUNNING JOBS INFO
squeue > squeue.dat
# FROM SQUEUE, GET ALL IDS WITH SPECIFIED USERNAME
> $RUNNING_IDS ## Erase the previous state of running IDs
while read LINE;
do 
    ID=$(echo $LINE | awk  '{print $1}')
    JOB_USER=$(echo $LINE | awk '{print $4}')
    if [ "$JOB_USER" == "$USER" ] ; then
        echo $ID >> $RUNNING_IDS
    fi
done < squeue.dat


####### ==ERROR TRACKING AMENDMENT==
# Gather current error messages as ids, then check current id for membership in err_list
while read ERROR; do
    # GET JOB ID FOR CURRENT MESSAGE
    ERR_ID=$(echo $ERROR | awk '{print $1}' | sed 's/.*xx//g' | sed 's/[^0-9]*//g')
    echo $ERR_ID >> $ERRED_IDS
done < $ERROR_LOG

# ITERATE OVER ERROR MESSAGES TO SEE IF THE JOB HAS ERRED
#        while read ERROR; do
#            # GET JOB ID FOR CURRENT MESSAGE
#            ERR_ID=$(echo $ERROR | awk '{print $1}' | sed 's/.*xx//g' | sed 's/[^0-9]*//g')
#            # IF THE ERROR ID IS THE JOB ID 
#            if [ "$JOB_ID" == "$ERR_ID" ] ; then
#                # Check if the job is from our supertask
#                if [ -f "$ALL_TASKS"/"$JOB_NAME" ] ; then 
#                    echo "$JOB_NAME HAS ERRED"
#                    cp "$ALL_TASKS"/"$JOB_NAME" "$ERR_TASKS"
#                    rm -f "$RUNNING_TASKS"/"$JOB_NAME"
#                    continue
#                fi
#            fi
#        done < $ERROR_LOG


# ITERATE OVER LAUNCHED AND SUPPOSEDLY RUNNING JOBS
while read RECORD; do
    JOB_NAME=$(echo $RECORD | awk  '{print $1}')
    JOB_ID=$(echo $RECORD | awk  '{print $5}')
    # SAVE THE RECORD IF JOB IS INDEED STILL RUNNING (as shown in squeue)
    if grep -q "$JOB_ID" "$RUNNING_IDS" ; then
        echo $RECORD >> $BUFFER 
    else 
        # IF THE JOB ID IS AMONG ERRED ONES
        if [ $(cat $ERRED_IDS | grep -c $JOB_ID) -eq 1 ] ; then
             # Check if the job is from our supertask
                if [ -f "$ALL_TASKS"/"$JOB_NAME" ] ; then 
                    echo "$JOB_NAME HAS ERRED"
                    cp "$ALL_TASKS"/"$JOB_NAME" "$ERR_TASKS"
                    rm -f "$RUNNING_TASKS"/"$JOB_NAME"
                    continue
                fi
        # FINALLY, IF THE JOB IS NOT RUNNING AND NEITHER HAS ERRED, CONSIDER IT DONE
        else
            if [ -f "$ALL_TASKS"/"$JOB_NAME" ] ; then
                cp "$ALL_TASKS"/"$JOB_NAME" "$DONE_TASKS"
                rm -f "$RUNNING_TASKS"/"$JOB_NAME"
                echo "$JOB_NAME is complete."
            fi
        fi
    fi        
done < "$LAUNCHED_JOBS"
# SUBSTITUTE INITIAL LIST OF RUNNING JOBS WITH BUFFER THAT CONTAINS UDPATED INFO
mv $BUFFER $LAUNCHED_JOBS

#./supertask_run.sh: line 71: $LAUNCHED_IDS: ambiguous redirect
# mv: cannot stat ‘WW/buffer.dat’: No such file or directory

# Track the datetime of the current iteration
echo ""
echo ""
echo "< < < Iteration >> $(date) > > >"
echo ""

#>#>#
#>#># TRACK THE REMAINING SCRIPTS TO RUN
#>#>#
update_remaining $SUPERTASKFOLDER -verbose

NUM_ALLTASKS=`file_count $ALL_TASKS`
NUM_RUNNING=`file_count $RUNNING_TASKS`
NUM_TODO=`file_count $TODO_TASKS`

#># GET THE NUBMER OF VACANT RUNS ON THE COMPUTER
if [[ $NUM_RUNNING -ge $MAX_PARALLEL_JOBS ]] ; then
    NUM_VACANT=0
else
    NUM_VACANT=$(expr $MAX_PARALLEL_JOBS - $NUM_RUNNING)
fi

if [[ $NUM_TODO -le $NUM_VACANT ]] ; then
    NUM_TO_RUN=$NUM_TODO
else
    NUM_TO_RUN=$NUM_VACANT
fi

if [[ $NUM_TO_RUN -gt 0 ]] ; then
    echo "##################################"
    echo "#   LAUNCHING $NUM_TO_RUN JOBS   #"
    echo "##################################"
    ./run_tasks.sh "$SUPERTASKFOLDER" $NUM_TO_RUN # $DRY_RUN not really needed for now - if numtorun is ) then it's dry
elif [[ $NUM_TODO -gt 0 ]] ; then
    echo "##################################"
    echo "#    NO VACANT SPOTS FOR NOW     #"
    echo "##################################"
else 
    echo "##################################"
    echo "#     ALL JOBS ARE SUBMITTED     #"
    echo "##################################"
fi

update_remaining $SUPERTASKFOLDER

echo "[ CURRENT STATS ]"
echo "| total:    " `file_count $ALL_TASKS`
echo "| remaining:" `file_count $TODO_TASKS`
echo "| running:  " `file_count $RUNNING_TASKS`
echo "| complete: " `file_count $DONE_TASKS`
echo "| erred:    " `file_count $ERR_TASKS`
echo "_____________________________"
