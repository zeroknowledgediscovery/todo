
#
#   HELPER FUNCTIONS OF PHNX
#



#># Read running configs from a cfg file within payload folder
#>#

read_configs()
{
    CFG_FILE=$1
    while CFG== read -r key val ; do
        val=${val%\"}; val=${val#\"}; key=${key#export };
        printf -v $key "$val"
    done < $CFG_FILE
}

#># Return number of files in te given folder
#>#
file_count()
{
    FILENAME=$1
    ls "$FILENAME" | wc -l
}

#># UPDATE THE LIST OF REMANING SCRIPTS WITHIN SUPERTASK
#>#
label()
{
    echo $(echo $1 | awk '{print $1}')
}

#># UPDATE THE LIST OF REMANING SCRIPTS WITHIN SUPERTASK
#>#
status()
{
    string=$1
    echo $(echo $string | awk '{print $2}')
}

#># UPDATE THE LIST OF REMANING SCRIPTS WITHIN SUPERTASK
#>#
update_remaining()
{
    SUPERTASK=$1
    VERBOSE_FLAG=0
    if [ $# -gt 1 ] ; then
        VERBOSE_FLAG=1
    fi

    ALL_FILES="$SUPERTASK"/'ALL_TASKS'
    DONE_FILES="$SUPERTASK"/'DONE_TASKS'
    IN_PROGRESS="$SUPERTASK"/'RUNNING_TASKS'
    FAILED="$SUPERTASK"/'ERR_TASKS'
    TODO_TASKS="$SUPERTASK"/'TODO_TASKS'

    # CLEAN UP THE CURRENT CONTENTS OF REMAINING
    rm -f "$TODO_TASKS"/*

    # COPY ALL SCRIPTS THAT ARE NOT DONE AND NOT RUNNING
    # FOR LATER :: MB ALSO EXCLUDE THE ERRED ONES, NEED TO CLARIFY
    if [ $VERBOSE_FLAG == 1 ] ; then
        echo " => Jobs to be run ::"
    fi
    for FILEPATH in "$ALL_FILES"/*; do
        FILENAME=$(basename $FILEPATH)
        if [ ! -f "$DONE_FILES"/"$FILENAME" ] && [ ! -f "$IN_PROGRESS"/"$FILENAME" ] && [ ! -f "$FAILED"/"$FILENAME" ];
        then
            # COPY FILE>>> 
            if [ $VERBOSE_FLAG == 1 ] ; then
                echo "$FILENAME"
            fi
            
            cp "$ALL_FILES"/"$FILENAME" "$TODO_TASKS"
        fi
    done;
}