FROM loum/hadoop-hive:3.1.2

ARG SPARK_VERSION=spark-3.0.0-preview2
RUN wget -p /tmp http://apache.mirror.digitalpacific.com.au/spark/${SPARK_VERSION}/${SPARK_VERSION}-bin-hadoop3.2.tgz

RUN tar xzf /tmp/${SPARK_VERSION}-bin-hadoop3.2.tar.gz -C /opt && \
  ln -s /opt/apache-${SPARK_VERSION}-bin-hadoop3.2 /opt/spark && \
  rm /tmp/${SPARK_VERSION}-bin-hadoop3.2.tar.gz && \
  chown -R root:root /opt/${SPARK_VERSION}-bin-hadoop3.2

#ARG HIVE_VERSION=hive-3.1.2
#
#RUN wget -P /tmp http://apache.mirror.serversaustralia.com.au/hive/${HIVE_VERSION}/apache-${HIVE_VERSION}-bin.tar.gz
#RUN tar xzf /tmp/apache-${HIVE_VERSION}-bin.tar.gz -C /opt && \
#  ln -s /opt/apache-${HIVE_VERSION}-bin /opt/hive && \
#  rm /tmp/apache-${HIVE_VERSION}-bin.tar.gz && \
#  chown -R root:root /opt/apache-${HIVE_VERSION}-bin
#
## Add Hive executables to hdfs user PATH.
#USER hdfs
#RUN sed -i 's/:$PATH/:\/opt\/hive\/bin:$PATH/' ~/.profile
#
## Temporary workaround for conflicting guava jars.
##
## See https://stackoverflow.com/questions/58176627/how-can-i-ask-hive-to-provide-more-detailed-error
## for more detail.
#USER root
#RUN rm /opt/hive/lib/guava-19.0.jar && \
#  cp /opt/hadoop/share/hadoop/common/lib/guava-27.0-jre.jar /opt/hive/lib/
#
#COPY files/hive-site.xml /opt/hive/conf/
#
#COPY scripts/hive-bootstrap.sh /hive-bootstrap.sh
#CMD [ "/hive-bootstrap.sh" ]
#
## Hiverserver2 port.
#EXPOSE 10000
