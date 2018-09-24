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

ALL_TASKS="$SUPERTASK"/ALL_TASKS
DONE_TASKS="$SUPERTASK"/DONE_TASKS
ERR_TASKS="$SUPERTASK"/ERR_TASKS

start_time=`date '+%s'`

echo " >> Iterator started"
echo " >> New iteration each $INTERVAL seconds"


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
    exit 1
fi
let TIME="$INTERVAL"
sleep $TIME
exec $0 $1 $2 $3 $4 $5

