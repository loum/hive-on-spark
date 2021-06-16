ARG SPARK_VERSION
ARG SPARK_RELEASE
ARG UBUNTU_BASE_IMAGE
ARG HADOOP_HIVE_BASE_IMAGE

FROM ubuntu:$UBUNTU_BASE_IMAGE AS builder

ARG OPENJDK_8_HEADLESS
RUN apt-get update && apt-get install -y --no-install-recommends\
 wget\
 ca-certificates\
 git\
 openjdk-8-jdk-headless=$OPENJDK_8_HEADLESS

WORKDIR /tmp
ARG SPARK_VERSION
RUN git clone --depth 1 --branch v$SPARK_VERSION https://github.com/apache/spark.git

# Build a runnable distribution.
WORKDIR spark
ENV MAVEN_OPTS="-Xmx2g -XX:ReservedCodeCacheSize=2g"
ARG SPARK_RELEASE
RUN dev/make-distribution.sh\
 --name without-hadoop\
 --tgz\
 -Pyarn\
 -Phadoop-provided

### builder stage end.

ARG HADOOP_HIVE_BASE_IMAGE
FROM loum/hadoop-hive:$HADOOP_HIVE_BASE_IMAGE

USER root

# Install python to support pyspark.
ARG PYTHON_38
RUN apt-get update && apt-get install -y --no-install-recommends\
 python3.8="${PYTHON_38}" &&\
 rm -rf /var/lib/apt/lists/*
RUN update-alternatives --install /usr/bin/python python3 /usr/bin/python3.8 1

ARG SPARK_RELEASE
COPY --from=builder /tmp/spark/$SPARK_RELEASE.tgz /opt
RUN tar zxf /opt/$SPARK_RELEASE.tgz -C /opt\
 && ln -s /opt/$SPARK_RELEASE /opt/spark\
 && rm /opt/$SPARK_RELEASE.tgz

# Spark config.
ARG SPARK_HOME=/opt/spark
COPY files/spark-env.sh $SPARK_HOME/conf/spark-env.sh
COPY files/spark-defaults.conf $SPARK_HOME/conf/spark-defaults.conf

# Hadoop YARN
RUN mv /opt/hadoop/etc/hadoop/yarn-site.xml /opt/hadoop/etc/hadoop/yarn-site.xml.orig
COPY files/yarn-site.xml /opt/hadoop/etc/hadoop/yarn-site.xml

# Set Hive configuration settings.
#
# hive.execution.engine mr => spark
# hive.exec.parallel false => true
RUN cp /opt/hive/conf/hive-site.xml /opt/hive/conf/hive-site.xml.bak
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN cat /opt/hive/conf/hive-site.xml.bak |\
 sed -n '1h;1!H;${g;s|execution.engine</name>\n    <value>mr|execution.engine</name>\n    <value>spark|;p;}' |\
 sed -n '1h;1!H;${g;s|exec.parallel</name>\n    <value>false|exec.parallel</name>\n    <value>true|;p;}'\
 > /opt/hive/conf/hive-site.xml

ARG SPARK_VERSION
ARG SCALA_VERSION=2.11
RUN ln -s ${SPARK_HOME}/jars/scala-library-${SCALA_VERSION}.*.jar /opt/hive/lib && \
  ln -s ${SPARK_HOME}/jars/spark-core_${SCALA_VERSION}-${SPARK_VERSION}.jar /opt/hive/lib && \
  ln -s ${SPARK_HOME}/jars/spark-unsafe_${SCALA_VERSION}-${SPARK_VERSION}.jar /opt/hive/lib && \
  ln -s ${SPARK_HOME}/jars/spark-network-common_2.11-${SPARK_VERSION}.jar /opt/hive/lib

COPY scripts/spark-bootstrap.sh /spark-bootstrap.sh

# YARN ResourceManager port.
EXPOSE 8032

# YARN ResourceManager webapp port.
EXPOSE 8088

# YARN NodeManager webapp port.
EXPOSE 8042

# Spark HistoryServer web UI port.
EXPOSE 18080

# HiveServer2 port.
EXPOSE 10000

# Web UI for HiveServer2 port.
EXPOSE 10002

# Start user run context.
USER hdfs
WORKDIR /home/hdfs

RUN sed -i "s|^export PATH=|export PATH=${SPARK_HOME}\/bin:|" ~/.bashrc

CMD [ "/spark-bootstrap.sh" ]
