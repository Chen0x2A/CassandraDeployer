#!/bin/bash

# Function to download Cassandra 先在登陆节点下载Cassandra
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
    

    # update CASSANDRA_HOME PATH
    if ! grep -q "export CASSANDRA_HOME=\$CASSANDRA_PATH" ~/.bash_profile; then
        echo "export CASSANDRA_HOME=\$CASSANDRA_PATH" >> ~/.bash_profile 
    else
        echo "export CASSANDRA_HOME=\$CASSANDRA_PATH already exists. Skipping."
    fi

    # update Cassandra PATH
    if ! grep -q "export PATH=\$PATH:\$CASSANDRA_HOME/bin" ~/.bash_profile; then
        echo "export PATH=\$PATH:\$CASSANDRA_HOME/bin" >> ~/.bash_profile
    else
        echo "export PATH=\$PATH:\$CASSANDRA_HOME/bin already exists. Skipping."
    fi 

    # update JAVA_HOME PATH
    if ! grep -q "export JAVA_HOME=\$JAVA_PATH" ~/.bash_profile; then
        echo "export JAVA_HOME=\$JAVA_PATH" >> ~/.bash_profile 
        echo "set JAVA_HOME successfully"
    else
        echo "export JAVA_HOME=\$JAVA_PATH already exists. Skipping."
    fi

    # update JDK PATH
    if ! grep -q "export PATH=\$JAVA_HOME/bin:\$PATH" ~/.bash_profile; then
        echo "export PATH=\$JAVA_HOME/bin:\$PATH" >> ~/.bash_profile
        echo "set Java PATH successfully"
    else
        echo "export PATH=\$JAVA_HOME/bin:\$PATH already exists. Skipping."
    fi
    
    cat ~/.bash_profile

}

# initial Cassandra
function initial (){

    echo "initial is called in $HOSTNAME."
     # to initial all configuration documents
    if [ -d "/temp/$USER/Cassandra/" ]; then
        rm -rf /temp/$USER/Cassandra
        mkdir -p /temp/$USER/Cassandra
    fi  
    mkdir -p /temp/$USER/Cassandra
    cp -r $HOME/Cassandra/apache-cassandra-4.1.3 /temp/$USER/Cassandra/
    sleep 20 #wait 20 s , ensure all nodes finish initialization
   }

function shareIP(){
    # Retrieve the machine's IP address
    echo "ShareIP is called in $HOSTNAME."
    mkdir -p  $HOME/Cassandra/hostlist
    # Each compute node executes the script and uploads its own IP to the shared folder by updating a txt file named after its own node.
    if [ -f " $HOME/Cassandra/hostlist/$HOSTNAME.txt" ]; then
        rm  $HOME/Cassandra/hostlist/$HOSTNAME.txt
    fi
    #get IP in current node
    LOCAL_IP=$(ifconfig eno0 2>/dev/null | awk '/inet / {print $2}') # Attempt to get IP from eno0
    if [ -z "$LOCAL_IP" ]; then
        LOCAL_IP=$(ifconfig eno1 2>/dev/null | awk '/inet / {print $2}') # Attempt to get IP from eno1
    fi
    if [ -z "$LOCAL_IP" ]; then
        LOCAL_IP=$(ifconfig enp2s0f0 2>/dev/null | awk '/inet / {print $2}') # Attempt to get IP from enp2s0f0
    fi
    if [ -z "$LOCAL_IP" ]; then
        LOCAL_IP=$(ifconfig enp2s0f1 2>/dev/null | awk '/inet / {print $2}') # Attempt to get IP from enp2s0f1
    fi

    echo $LOCAL_IP >  $HOME/Cassandra/hostlist/$HOSTNAME.txt
    sleep 20
}

function getIP(){
    # Get the first three IP addresses from $HOME/Cassandra/hostlist, set the first three nodes as Cassandra seed nodes
    IPs=$(cat $HOME/Cassandra/hostlist/*.txt | head -n 3 | paste -sd "," -)
    
    echo "GetIP is called in $HOSTNAME." # Print out which node called this function
    echo "show all IP address:" & cat  $HOME/Cassandra/hostlist/*.txt
    echo "show seed IP address:$IPs"
    # Update cassandra.yaml configuration file
    sed -i "s/- seeds: \"127.0.0.1:7000\"/- seeds: \"$IPs\"/" /temp/$USER/Cassandra/apache-cassandra-4.1.3/conf/cassandra.yaml
    sed -i "s/listen_address: localhost/listen_address: $LOCAL_IP/" /temp/$USER/Cassandra/apache-cassandra-4.1.3/conf/cassandra.yaml
    sed -i "s/rpc_address: localhost/rpc_address: $LOCAL_IP/"  /temp/$USER/Cassandra/apache-cassandra-4.1.3/conf/cassandra.yaml
    # Update max_heap_size
    # sed -i 's/MAX_HEAP_SIZE=".*"/MAX_HEAP_SIZE="16000M"/' /temp/$USER/Cassandra/apache-cassandra-4.1.3/conf/cassandra-env.sh
    # Change timeout durations
    # sed -i 's/read_request_timeout: [0-9]\+ms/read_request_timeout: 3600000ms/' /temp/$USER/Cassandra/apache-cassandra-4.1.3/conf/cassandra.yaml
    # sed -i 's/range_request_timeout: [0-9]\+ms/range_request_timeout: 3600000ms/' /temp/$USER/Cassandra/apache-cassandra-4.1.3/conf/cassandra.yaml
    sed -i 's/write_request_timeout: [0-9]\+ms/write_request_timeout: 36000ms/' /temp/$USER/Cassandra/apache-cassandra-4.1.3/conf/cassandra.yaml
    # sed -i 's/counter_write_request_timeout: [0-9]\+ms/counter_write_request_timeout: 3600000ms/' /temp/$USER/Cassandra/apache-cassandra-4.1.3/conf/cassandra.yaml
    # sed -i 's/cas_contention_timeout: [0-9]\+ms/cas_contention_timeout: 3600000ms/' /temp/$USER/Cassandra/apache-cassandra-4.1.3/conf/cassandra.yaml
    # sed -i 's/truncate_request_timeout: [0-9]\+ms/truncate_request_timeout: 3600000ms/' /temp/$USER/Cassandra/apache-cassandra-4.1.3/conf/cassandra.yaml
    # sed -i 's/request_timeout: [0-9]\+ms/request_timeout: 3600000ms/' /temp/$USER/Cassandra/apache-cassandra-4.1.3/conf/cassandra.yaml
    # Enable materialized views
    sed -i 's/materialized_views_enabled: false/materialized_views_enabled: true/' /temp/$USER/Cassandra/apache-cassandra-4.1.3/conf/cassandra.yaml

    sleep 20
}


function setJDK(){
    echo "setJDK is called in $HOSTNAME."
    # Create JDK directory
    if [ ! -d "/temp/$USER/java/jdk-11.0.19" ]; then
        mkdir -p /temp/$USER/java
        cp -r $HOME/java/jdk-11.0.19 /temp/$USER/java/ # First download jdk in $HOME
    fi  

    echo $(java --version)
    sleep 20
    #
}



# 1. Variable settings -------------------------------------------------------
source ~/.bash_profile # Update environment variables
HOSTNAME=$(/bin/hostname) 
CASSANDRA_PATH="/temp/$USER/Cassandra/apache-cassandra-4.1.3" # Path to Cassandra installation
JAVA_PATH="/temp/$USER/java/jdk-11.0.19"  # Path to JDK installation



# 2. Cluster configuration
rm -rf $HOME/Cassandra/hostlist
initial # Copy Cassandra folder from $HOME to local temp/$USER
setJDK # Copy JDK folder from $HOME to local temp/$USER
echo $(java --version)
shareIP # Each compute node uploads its own IP to $HOME/Cassandra/hostlist
getIP # Get all node ips from $HOME/Cassandra/hostlist/*.txt, take the first three ips as seed

# 3. Check configuration files
echo "show cassandra.yaml on $HOSTNAME" # Print configuration files of each node
sed -n '553p;763p;859p'
