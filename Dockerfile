ARG SPARK_TAG=hadoop3-1-without-hive
ARG SPARK_VERSION=spark-2.4.5-bin-${SPARK_TAG}

FROM ubuntu:bionic-20200311 AS builder

RUN apt-get update && apt-get install -y --no-install-recommends\
 git\
 curl\
 openjdk-8-jdk-headless=8u242-b08-0ubuntu3~18.04

RUN git clone --depth 1 --branch v2.4.5 https://github.com/apache/spark.git
WORKDIR /spark
ARG SPARK_TAG
ARG SPARK_VERSION
RUN dev/make-distribution.sh --name "${SPARK_TAG}" --tgz "-Pyarn,hadoop-provided,hadoop-3.1,parquet-provided,orc-provided"
RUN tar xzf "${SPARK_VERSION}.tgz" && chown -R root:root "${SPARK_VERSION}"

### downloader layer end

FROM loum/hadoop-hive:3.2.1-3.1.2-3

USER root

ARG SPARK_VERSION

WORKDIR /opt

COPY --from=builder "/spark/${SPARK_VERSION}" spark

# Spark config.
COPY files/spark-env.sh spark/conf/spark-env.sh
COPY files/spark-defaults.conf spark/conf/spark-defaults.conf

# Hadoop YARN
RUN mv hadoop/etc/hadoop/yarn-site.xml hadoop/etc/hadoop/yarn-site.xml.orig
COPY files/yarn-site.xml hadoop/etc/hadoop/yarn-site.xml

# Set Hive configuration settings.
#
# hive.execution.engine mr => spark
# hive.exec.parallel false => true
RUN cp hive/conf/hive-site.xml hive/conf/hive-site.xml.bak
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN cat hive/conf/hive-site.xml.bak |\
 sed -n '1h;1!H;${g;s|execution.engine</name>\n    <value>mr|execution.engine</name>\n    <value>spark|;p;}' |\
 sed -n '1h;1!H;${g;s|exec.parallel</name>\n    <value>false|exec.parallel</name>\n    <value>true|;p;}'\
 > hive/conf/hive-site.xml

ARG SPARK_HOME=/opt/spark

RUN ln -s ${SPARK_HOME}/jars/scala-library-2.11.12.jar hive/lib && \
  ln -s ${SPARK_HOME}/jars/spark-core_2.11-2.4.5.jar hive/lib && \
  ln -s ${SPARK_HOME}/jars/spark-unsafe_2.11-2.4.5.jar hive/lib && \
  ln -s ${SPARK_HOME}/jars/spark-network-common_2.11-2.4.5.jar hive/lib

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

### start user run context.
USER hdfs
WORKDIR /home/hdfs

RUN sed -i "s|^export PATH=|export PATH=${SPARK_HOME}\/bin:|" ~/.bashrc

CMD [ "/spark-bootstrap.sh" ]
