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

# Copy over the Spark JARs to HDFS.
$HADOOP_HOME/bin/hdfs dfs -mkdir /tmp/spark
$HADOOP_HOME/bin/hdfs dfs -mkdir /tmp/spark/yarn
$HADOOP_HOME/bin/hdfs dfs -mkdir /tmp/spark/yarn/archive
$HADOOP_HOME/bin/hdfs dfs -copyFromLocal /opt/spark/jars/* /tmp/spark/yarn/archive/

if [ $loop_counter -lt $max_loops ]
then
    $HADOOP_HOME/bin/hdfs dfs -mkdir /tmp/spark-events
    /opt/spark/sbin/start-history-server.sh
else
    echo "ERROR: Spark HistoryServer did not start"
fi

# Start the Livy server.
HADOOP_CONF_DIR=/opt/hadoop/etc/hadoop SPARK_HOME=/opt/spark /opt/livy/bin/livy-server start

# Block until we signal exit.
trap 'exit 0' TERM
while true; do sleep 0.5; done
