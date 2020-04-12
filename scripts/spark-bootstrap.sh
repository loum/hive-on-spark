#!/bin/sh

nohup sh -c /hive-bootstrap.sh &

# Start Spark HistoryServer.
#
# Create shared "spark.eventLog.dir"/"spark.history.fs.logDirectory" directories in HDFS.
HADOOP_HOME=/opt/hadoop
loop_counter=0
max_loops=15
sleep_period=5
until [ $loop_counter -ge $max_loops ]
do
    $HADOOP_HOME/bin/hdfs dfs -mkdir /tmp 2>/dev/null && break
    loop_counter=$((loop_counter+1))
    sleep $sleep_period
done

if [ $loop_counter -lt $max_loops ]
then
    $HADOOP_HOME/bin/hdfs dfs -mkdir /tmp/spark-events
    /opt/spark/sbin/start-history-server.sh
else
    echo "ERROR: Spark HistoryServer did not start"
fi

# Block until we signal exit.
trap 'exit 0' TERM
while true; do sleep 0.5; done
