#
#   SUPERTASK INITIALIZER
#


#># import helper functions
source ./toolbox.sh


USAGE="Usage:  <SUPERTASK> <PAYLOAD>"

###########################################
#                PART 0                   # 
#            SPECIFY INIT PARAMS          #
###########################################
SUPERTASK="$1"
PAYLOAD="$2"

##################################################
# EXTRACT RUNNING PARAMS from running_config.txt #
#                INTO VARIABLES                  #
#    see toolbox.sh::read_configs for details    #
##################################################
read_configs "$PAYLOAD"/running_config.txt

##################################################
#  ENABLE EXECUTION OF ALL FILES IN PAYLOAD/bin  #
##################################################
EXEC_DIR="$PAYLOAD"/bin
chmod -R ugo+x "$EXEC_DIR"

###########################################
#                PART 1                   # 
#           INITIALIZE THE FOLDERS        #
###########################################
supertask_dir="$SUPERTASK"
echo "[[[[[[[[ $SUPERTASK IS BEING INITIALIZED ]]]]]]]]"
mkdir $supertask_dir
mkdir "$supertask_dir"/'ALL_TASKS'
mkdir "$supertask_dir"/'TODO_TASKS'
mkdir "$supertask_dir"/'DONE_TASKS'
mkdir "$supertask_dir"/'RUNNING_TASKS'
mkdir "$supertask_dir"/'ERR_TASKS'
mkdir "$supertask_dir"/'STATS'
touch "$supertask_dir"/phnx.out
touch "$supertask_dir"/phnx.err

###########################################################
#                       PART 2                            # 
#      CREATE TASK EXECUTION FILE FOR EACH TASKLINE       #
###########################################################

## OPEN THE FILES FROM THE PAYLOAD
TASKDIR="$supertask_dir"/ALL_TASKS
DYNAMIC_TASKDIR="$supertask_dir"/TODO_TASKS
OUTFILE=$PWD/"$supertask_dir"/phnx.out
ERRFILE=$PWD/"$supertask_dir"/phnx.err
#OUTFILE="$BASEPATH"/"$supertask_dir"/phnx.out
#ERRFILE="$BASEPATH"/"$supertask_dir"/phnx.err

PROG_CALLS="$PAYLOAD"/program_calls.txt
DEPENDENCIES="$PAYLOAD"/dependencies.txt

#># ###################################################
#># WRITE WRAPPED CALLS, LINE BY LINE
#># ###################################################
ID=0
while read PROGRAM_CALL;
do
    # SPECIFY THE SBC SCRIPT FILENAME
    SBC="$TASKDIR"/"$SUPERTASK"_"$ID".sbc

    # DEFINE SCRIPT HEADER
    echo '#!/bin/bash' > $SBC
    echo '#SBATCH --job-name='"$SUPERTASK"_"$ID" >> $SBC 
    echo '#SBATCH --output='"$OUTFILE" >> $SBC
    echo '#SBATCH --error='"$ERRFILE" >> $SBC
    echo '#SBATCH --workdir='"$PAYLOAD" >> $SBC
    echo '#SBATCH --time='"$RUNTIME"':00:00' >> $SBC
    echo '#SBATCH --mem='"$MEM" >> $SBC
    echo '#SBATCH --qos='"$QOS" >> $SBC
    echo '#SBATCH --nodes='"$NODES" >> $SBC
    echo '#SBATCH --ntasks-per-node='"$TPC" >> $SBC
    echo '#SBATCH --partition='"$PARTITION" >> $SBC
    
    ### WRITE OUT ALL THE DEPENDENCIES NEEDED
    while read dependency; do
        echo 'module load '"$dependency" >> $SBC
    done < $DEPENDENCIES

    ##
    ## WRITE THE PROGRAM CALL ITSELF
    ##  
    echo "$PROGRAM_CALL" >> $SBC  

    echo '' >> $SBC

    #># INCREMENT THE ID
    ID=$(expr $ID + 1)

done < $PROG_CALLS

echo "$ID Jobs received."

##########################################
#                 PART 3                 #
#           LAUNCH THE PROGRAM           #
########################################## 

./iterator.sh $SUPERTASK $INTERVAL $USER $MAX_PARALLEL_JOBS $RUNTIME_LIMIT
