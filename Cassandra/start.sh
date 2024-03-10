#!/bin/bash

function test(){
    echo "test  - $(date)"
    # Network test
    echo "Current port status of $(hostname)" & date '+%Y-%m-%d %H:%M:%S'
    netstat -tuln
    # Check node status
    echo "nodetool status:  - $(date)"
    $CASSANDRA_HOME/bin/nodetool status
    echo "nodetool describecluster:  - $(date)"
    $CASSANDRA_HOME/bin/nodetool describecluster
    # View the created materialized views
    echo "DESCRIBE MATERIALIZED VIEWS; " | cqlsh $LOCAL_IP 9042
    # The last node performs query testing
    if [ "$HOSTNAME" == "${hostlist[4]}" ]; then
        echo "---------------------------execute query-----------------------------------"
        $HOME/apache-cassandra-4.1.3/bin/cqlsh $LOCAL_IP 9042 -f ~/Cassandra/query.cql
    fi
    # View information on all tables in the sampleDB cluster
    nodetool tablestats sampleDB
}


# copy
function import_table(){
    local table_name=$1
    local error_file=$2
    local copy_command="COPY sampleDB.${table_name} (columns) FROM '${error_file}' WITH DELIMITER=',' AND HEADER=FALSE AND CHUNKSIZE=500 AND NUMPROCESSES=4;"

    local before_files=($(ls ${ERROR_DIR}import_${table_name}.err* 2> /dev/null))

    #  Complete the copy statement
    case "$table_name" in
        "R1")
            copy_command=${copy_command//(columns)/(R1_ID)}
            ;;
        "R2")
            copy_command=${copy_command//(columns)/(R2_ID)}
            ;;
        *)
            echo "No matching table found for $table_name"
            return 1
    esac
    
    echo "Executing: $copy_command"
    echo "$copy_command" | cqlsh $LOCAL_IP 9042
    echo "COPY command for $table_name completed."
    # After executing the COPY command, get the list of error files again
    local after_files=($(ls ${ERROR_DIR}import_${table_name}.err* 2> /dev/null))

    # Compare the list of error files before and after to check for new files
    local new_files=()
    for file in "${after_files[@]}"; do
        if [[ ! " ${before_files[@]} " =~ " ${file} " ]]; then
            new_files+=("$file")
        fi
    done

    # If no new error files are found, delete the old error file
    if [ ${#new_files[@]} -eq 0 ]; then
        echo "No new error files found for $table_name. Deleting old error file."
        rm "$error_file"
    else
        echo "New error files found for $table_name: ${new_files[*]}"
    fi

    return 1
    
}

# 1. Variable assignment
source ~/.bash_profile # Update Cassandra Java path
HOSTNAME=$(/bin/hostname) # The name of the current server
LOCAL_IP=$(cat $HOME/Cassandra/hostlist/$HOSTNAME.txt) # The IP of the current server
hostlist=($(ls $HOME/Cassandra/hostlist | sed 's/\.txt//')) # Array of all server names
hostlist_str="${hostlist[@]}" # String of all server names
IPs=$(cat $HOME/Cassandra/hostlist/*.txt | paste -sd "," -) # String of all server IPs
export hostlist_str # Export to the current shell environment for use by Python programs
export IPs # Export to the current shell environment for use by Python programs
pip install cassandra-driver filelock

# 2. Copy the project csv files to the local temp
cp -r ~/project_files /temp/$USER/Cassandra/
sed -i 's/,null,/,0,/g' /temp/$USER/Cassandra/project_files/data_files/R1.csv # Handle null values in csv
sed -i 's/,null,/,0,/g' /temp/$USER/Cassandra/project_files/data_files/R2.csv # Handle null values in csv

# 3. Start in the order of the index value
# Get the index value of the current hostname in the hostlist array
for i in "${!hostlist[@]}"; do
    if [ "$HOSTNAME" == "${hostlist[$i]}" ]; then
        index=$i
        break
    fi
done
echo "index of $HOSTNAME is $index  - $(date)"
sleep $((200 * index))
echo "start Cassandra - $(date)"
$CASSANDRA_HOME/bin/cassandra



#4. Load Data with retry mechanism
if [ $index -eq 4 ]; then 
    # Path
    ERROR_DIR="$HOME/Cassandra/"
    sleep 300
    echo "DROP KEYSPACE!  - $(date)"
    echo "DROP KEYSPACE IF EXISTS sampleDB; " | cqlsh $LOCAL_IP 9042
    sleep 100
    echo "--------------------------excute loader----------------------------------"
    rm $ERROR_DIR*.err*
    cqlsh --request-timeout=3600 $LOCAL_IP 9042 -f ~/Cassandra/loader.cql
    # Reload all the err file until no more error files are produced
    while true; do
        error_files_found=false
        for error_file in "$ERROR_DIR"*.err*; do
            if [ -f "$error_file" ]; then
                error_files_found=true
                echo "found $error_file after execute loader.cql, reload error_file"
                table_name=$(echo "$(basename "$error_file")" | sed -e 's/import_sampledb_\(.*\)\.err.*/\1/') #没问题
                # Call import_table function to process each err file
                import_table "$table_name" "$error_file"
            fi
        done

        # If no error files are found, end the loop
        if [ "$error_files_found" = false ]; then
            echo "No error files found."
            touch $HOME/Cassandra/finishloader.flag
            break
        fi
        sleep 10
    done
    
fi

#5. Run testing transactions(Optional)
while true; do
    if [ -f "$HOME/Cassandra/finishloader.flag" ]; then
        echo "run transaction.py  - $(date)"
        ls $HOME/Cassandra/
        sleep 100
        # TODO you can run your testing program here
        #python $HOME/Cassandra/transaction.py
        break
    fi
    sleep 5 # sleep for 5 seconds and check again
done

#6. 
sleep 500
for ((i=1; i<=30; i++)); do
    test
    sleep 500
done

# rm -rf /temp/$USER/Cassandra/project_files
# echo "DROP KEYSPACE IF EXISTS sampleDB;" | cqlsh $LOCAL_IP 9042
