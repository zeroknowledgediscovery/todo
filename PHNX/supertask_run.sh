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
LOG="$STATS"/log.txt


# FILES TO TRACK IDS AND JOBNAMES RUNNING CURRENTLY
RUNNING_JOBS="running_now.dat"
touch $RUNNING_JOBS
RUNNING_IDS="running_ids.dat"
touch $RUNNING_IDS

#># GET NUMBER OF ALL TASKS
NUM_ALLTASKS=`file_count $ALL_TASKS`


# //////////////////////////////// #
#  TRACK COMPLETED & ERRED TASKS   #
# //////////////////////////////// #
touch "$LOG"
sacct --format="JobName, State" > "$LOG"


#
# HANDLE COMPLETED TASKS
#
while read LINE; do
    job=$(echo $LINE | awk  '{print $1}')
    status=$(echo $LINE | awk  '{print $2}')
    to_move="$job".sbc
    # MOVE SCRIPT TO DONE AND REMOVE FROM RUNNING IF IT IS COMPLETE
    if [ "$status" = "COMPLETED" ] ; then
        if [ -f "$ALL_TASKS"/"$to_move" ] ; then
            cp "$ALL_TASKS"/"$to_move" "$DONE_TASKS"
            rm -f "$RUNNING_TASKS"/"$to_move"
            echo "$to_move is complete."
        fi
    fi
done <"$LOG"

#
# EXTRACT THE CURRENT RUNNING TASKS' NAMES AND IDS
#
while read LINE; do
	echo $(echo $LINE | awk  '{print $5}') >> "$RUNNING_IDS"
done < "$RUNNING_JOBS"> "$RUNNING_IDS"

#
# CHECK FOR ERRED TASKS, ADD THEM TO ERRED AND REMOVE FROM RUNNING
#
while read ERROR; do
    err_id=$(echo $ERROR | awk '{print $1}' | sed 's/.*xx//g' | sed 's/[^0-9]*//g')
    if grep -q "$err_id" "running_ids.dat" ; then
        while read RECORD; do 
            job_name=$(echo $RECORD | awk  '{print $1}')
            job_id=$(echo $RECORD | awk  '{print $5}')
            to_move="%job_name"
            if [ $job_id -eq $err_id ] ; then
               if [ -f "$ALL_TASKS"/"$job_name" ] ; then 
                    echo "$job_name HAS ERRED"
                    cp "$ALL_TASKS"/"$job_name" "$ERR_TASKS"
                    rm -f "$RUNNING_TASKS"/"$job_name"
                fi 
            fi
        done < "$RUNNING_JOBS"
    fi
done < "$ERROR_LOG"

# Track the datetime of the current iteration
echo ""
echo ""
echo "< < < Iteration >> $(date) > > >"
echo ""

#>#>#
#>#># TRACK THE REMAINING SCRIPTS TO RUN
#>#>#
update_remaining $SUPERTASKFOLDER -verbose
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
