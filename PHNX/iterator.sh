#># import helper functions
source ./toolbox.sh

if [ $# -eq 0 ] ; then
    echo "USAGE:" "<SUPERTASK> <INTERVAL> <USER> <MAX_PARALLEL_JOBS>"
    exit
fi
SUPERTASK=$1
INTERVAL=$2
USER=$3
MAX_PARALLEL_JOBS=$4
RUNTIME_LIMIT=$5

ALL_TASKS="$SUPERTASK"/ALL_TASKS
DONE_TASKS="$SUPERTASK"/DONE_TASKS
ERR_TASKS="$SUPERTASK"/ERR_TASKS

start_time=`date '+%s'`

RUNTIME_SECS=$(($RUNTIME_LIMIT * 60 * 60))
TIME_TO_STOP=$(($RUNTIME_SECS - ($INTERVAL * 3)))
echo " >> Iterator started"
echo " >> New iteration each $INTERVAL seconds"

# Initial launch
./supertask_run.sh $SUPERTASK $USER $MAX_PARALLEL_JOBS

while true 
do
    # # Check if the 35-hours runtime limit comes up
    current_time=`date '+%s'`
    time_passed=$(($current_time - $start_time))
    if [ $time_passed -gt $RUNTIME_LIMIT ] ; then
        ./$0 $1 $2 $3 $4 $5
        break
    fi
    let TIME="$INTERVAL"
    sleep $TIME
    TOTAL=`file_count $ALL_TASKS`
    DONE=`file_count $DONE_TASKS`
    ERR=`file_count $ERR_TASKS`
    # TRACK HOW MANY TASKS WERE PROCESSED - EITHER SUCCESSFULLY OR NOT
    let PROCESSED=`expr $DONE + $ERR`

    # STOP ITERATOR IF ALL TASKS WERE PROCESSED
    if [ $PROCESSED -lt $TOTAL ] ; then
        ./supertask_run.sh $SUPERTASK $USER $MAX_PARALLEL_JOBS
    else 
        echo "============================================"
        echo "========= SUPERTASK RUN COMPLETE ==========="
        echo "============================================"
        echo "| complete: $DONE"
        echo "| erred:    $ERR"
        break
    fi
done
