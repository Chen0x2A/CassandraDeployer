# Function to download Cassandra - first download Cassandra in ~/
function download_cassandra ()
{
    
    # Create the Cassandra directory if it doesn't exist
    mkdir -p $HOME/Cassandra
    
    # Navigate to the Cassandra directory
    cd $HOME/Cassandra

    # Check if the tarball already exists
    if [ ! -f apache-cassandra-4.1.3-bin.tar.gz ]; then
        # If not, download Cassandra tarball directly into the Cassandra directory
        wget https://dlcdn.apache.org/cassandra/4.1.3/apache-cassandra-4.1.3-bin.tar.gz
    fi

    # Extract the tarball in the current directory, if the directory from extraction does not exist
    if [ ! -d apache-cassandra-4.1.3 ]; then
        tar xvfz apache-cassandra-4.1.3-bin.tar.gz
    fi
    
    
}

function setPATH(){
    
    # Remove old CASSANDRA_HOME environment variable
    sed -i '/export CASSANDRA_HOME=/d' ~/.bash_profile

    # Set new CASSANDRA_HOME environment variable
    echo "export CASSANDRA_HOME=$CASSANDRA_PATH" >> ~/.bash_profile
    echo "Set CASSANDRA_HOME to $CASSANDRA_PATH successfully"

    # Remove old Cassandra PATH environment variable
    sed -i '/export PATH=\$PATH:$CASSANDRA_HOME\/bin/d' ~/.bash_profile

    # Add new Cassandra PATH environment variable
    echo "export PATH=\$PATH:$CASSANDRA_HOME/bin" >> ~/.bash_profile
    echo "Added $CASSANDRA_HOME/bin to PATH successfully"

    # Remove old JAVA_HOME environment variable
    sed -i '/export JAVA_HOME=/d' ~/.bash_profile

    # Set new JAVA_HOME environment variable
    echo "export JAVA_HOME=$JAVA_PATH" >> ~/.bash_profile
    echo "Set JAVA_HOME to $JAVA_PATH successfully"

    # Remove old Java PATH environment variable
    sed -i '/export PATH=$JAVA_HOME\/bin:\$PATH/d' ~/.bash_profile

    # Add new Java PATH environment variable
    echo "export PATH=$JAVA_HOME/bin:\$PATH" >> ~/.bash_profile
    echo "Added $JAVA_HOME/bin to PATH successfully"
    
    # Print .bash_profile file to confirm changes
    cat ~/.bash_profile

    # Apply new environment variables
    source ~/.bash_profile


}

# 0. Environment variables
source ~/.bash_profile
JAVA_PATH="/temp/$USER/java/jdk-11.0.19" 
CASSANDRA_PATH="/temp/$USER/Cassandra/apache-cassandra-4.1.3"
setPATH


# 1. Download Cassandra on the login node
download_cassandra 

# 2. Copy Cassandra to the five compute nodes that will execute the transactions, and modify the configuration files
sbatch initialAll.sh
sleep 5

# 3. Loop check, as soon as initialization is completed, immediately execute the startAll script, load data, and execute transactions
while true; do
    # Use the sacct command to check the status of initial.sh
    latest_status=$(sacct | grep 'initial_C+' | tail -1 | awk '{print $6}')

    # Check if the status is COMPLETED
    if [[ $latest_status == "COMPLETED" ]]; then
        # Execute startAll.sh
        bash startAll.sh
        # Exit the loop after the task is completed
        break
    fi

    # Check every 0.1 seconds
    sleep 0.1

done