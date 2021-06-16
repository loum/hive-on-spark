.DEFAULT_GOAL := help

MAKESTER__REPO_NAME := loum
MAKESTER__CONTAINER_NAME := hive-on-spark

SPARK_VERSION := 2.4.8
SPARK_RELEASE := spark-$(SPARK_VERSION)-bin-without-hadoop

# Tagging convention used: <hive-version>-<spark-version>-<image-release-number>
MAKESTER__VERSION := 3.1.2-$(SPARK_VERSION)
MAKESTER__RELEASE_NUMBER := 1

include makester/makefiles/base.mk
include makester/makefiles/docker.mk
include makester/makefiles/python-venv.mk

UBUNTU_BASE_IMAGE := focal-20210416
HADOOP_HIVE_BASE_IMAGE := 3.2.1-3.1.2-4
OPENJDK_8_HEADLESS := 8u292-b10-0ubuntu1~20.04
PYTHON_38 := 3.8.5-1~20.04.3

MAKESTER__BUILD_COMMAND = $(DOCKER) build --rm\
 --no-cache\
 --build-arg SPARK_VERSION=$(SPARK_VERSION)\
 --build-arg SPARK_RELEASE=$(SPARK_RELEASE)\
 --build-arg UBUNTU_BASE_IMAGE=$(UBUNTU_BASE_IMAGE)\
 --build-arg HADOOP_HIVE_BASE_IMAGE=$(HADOOP_HIVE_BASE_IMAGE)\
 --build-arg OPENJDK_8_HEADLESS=$(OPENJDK_8_HEADLESS)\
 --build-arg PYTHON_38=$(PYTHON_38)\
 -t $(MAKESTER__IMAGE_TAG_ALIAS) .

MAKESTER__RUN_COMMAND := $(DOCKER) run --rm -d\
 --publish 10000:10000\
 --publish 10002:10002\
 --publish 8032:8032\
 --publish 8088:8088\
 --publish 8042:8042\
 --publish 18080:18080\
 --hostname $(MAKESTER__CONTAINER_NAME)\
 --name $(MAKESTER__CONTAINER_NAME)\
 $(MAKESTER__SERVICE_NAME):$(HASH)

init: clear-env makester-requirements

backoff:
	@$(PYTHON) makester/scripts/backoff -d "YARN ResourceManager" -p 8032 localhost
	@$(PYTHON) makester/scripts/backoff -d "YARN ResourceManager webapp UI" -p 8088 localhost
	@$(PYTHON) makester/scripts/backoff -d "YARN NodeManager webapp UI" -p 8042 localhost
	@$(PYTHON) makester/scripts/backoff -d "Spark HistoryServer web UI port" -p 18080 localhost
	@$(PYTHON) makester/scripts/backoff -d "Web UI for HiveServer2" -p 10002 localhost
	@$(PYTHON) makester/scripts/backoff -d "HiveServer2" -p 10000 localhost

controlled-run: run backoff

login:
	@$(DOCKER) exec -ti $(MAKESTER__CONTAINER_NAME) bash || true

root:
	@$(DOCKER) exec -ti -u 0 $(MAKESTER__CONTAINER_NAME) bash || true

hadoop-version:
	@$(DOCKER) exec -ti $(MAKESTER__CONTAINER_NAME) /opt/hadoop/bin/hadoop version || true

hive-version:
	@$(DOCKER) exec -ti $(MAKESTER__CONTAINER_NAME) bash -c\
 "HADOOP_HOME=/opt/hadoop /opt/hive/bin/hive --version" || true

spark-version:
	@$(DOCKER) exec $(MAKESTER__CONTAINER_NAME) bash -c\
 "HADOOP_CONF_DIR=/opt/hadoop/etc/hadoop /opt/spark/bin/spark-submit --version" || true

pi:
	@$(DOCKER) exec $(MAKESTER__CONTAINER_NAME) bash -c\
 "HADOOP_CONF_DIR=/opt/hadoop/etc/hadoop /opt/spark/bin/spark-submit --class org.apache.spark.examples.SparkPi\
 --files /opt/spark/conf/metrics.properties.template\
 --master yarn\
 --deploy-mode cluster\
 --driver-memory 1g\
 --executor-memory 1g\
 --executor-cores 1\
 /opt/spark/examples/jars/spark-examples_2.12-$(SPARK_VERSION).jar"

yarn-apps:
	@$(DOCKER) exec -ti $(MAKESTER__CONTAINER_NAME)\
 bash -c "/opt/hadoop/bin/yarn application -list -appStates ALL"

check-yarn-app-id:
	$(call check_defined, YARN_APPLICATION_ID)
yarn-app-log: check-yarn-app-id
	@$(DOCKER) exec -ti $(MAKESTER__CONTAINER_NAME)\
 bash -c "/opt/hadoop/bin/yarn logs -log_files stdout -applicationId $(YARN_APPLICATION_ID)"

beeline:
	@$(PYTHON) makester/scripts/backoff -d "HiveServer2" -p 10000 localhost
	@$(DOCKER) exec -ti $(MAKESTER__CONTAINER_NAME)\
 bash -c "HADOOP_HOME=/opt/hadoop /opt/hive/bin/beeline -u jdbc:hive2://localhost:10000"

beeline-cmd:
	@$(PYTHON) makester/scripts/backoff -d "HiveServer2" -p 10000 localhost
	@$(DOCKER) exec -ti $(MAKESTER__CONTAINER_NAME)\
 bash -c "HADOOP_HOME=/opt/hadoop /opt/hive/bin/beeline -u jdbc:hive2://localhost:10000 -e $(BEELINE_CMD)"

beeline-create: BEELINE_CMD = 'CREATE TABLE test (c CHAR(10));'

beeline-show: BEELINE_CMD = 'SHOW TABLES;'

beeline-insert: BEELINE_CMD = 'INSERT INTO TABLE test VALUES ('\''test'\'');'

beeline-select: BEELINE_CMD = 'SELECT * FROM test;'

beeline-drop: BEELINE_CMD = 'DROP TABLE test;'

beeline-create beeline-show beeline-insert beeline-select beeline-drop: beeline-cmd

pyspark: backoff
	@$(DOCKER) exec -ti $(MAKESTER__CONTAINER_NAME)\
 bash -c "/opt/spark/bin/pyspark"

spark-shell: backoff
	@$(DOCKER) exec -ti $(MAKESTER__CONTAINER_NAME)\
 bash -c "/opt/spark/bin/spark-shell"

help: makester-help docker-help python-venv-help
	@echo "(Makefile)\n\
  login                Login to container $(MAKESTER__CONTAINER_NAME) as user \"hdfs\"\n\
  hadoop-version       Hadoop version in running container $(MAKESTER__CONTAINER_NAME)\"\n\
  hive-version         Hive version in running container $(MAKESTER__CONTAINER_NAME)\"\n\
  spark-version        Spark version in running container $(MAKESTER__CONTAINER_NAME)\"\n\
  yarn-apps            List all YARN application IDs\n\
  yarn-app-log         Dump log for YARN application ID defined by \"YARN_APPLICATION_ID\"\n\
  beeline              Start beeline CLI on $(MAKESTER__CONTAINER_NAME)\n\
  beeline-create       Execute beeline command \"CREATE TABLE ...\" on $(MAKESTER__CONTAINER_NAME)\n\
  beeline-show         Execute beeline command \"SHOW TABLES\" on $(MAKESTER__CONTAINER_NAME)\n\
  beeline-insert       Execute beeline command \"INSERT INTO TABLE ...\" on $(MAKESTER__CONTAINER_NAME)\n\
  beeline-select       Execute beeline command \"SELECT * FROM ...\" on $(MAKESTER__CONTAINER_NAME)\n\
  beeline-drop         Execute beeline command \"DROP TABLE ...\" on $(MAKESTER__CONTAINER_NAME)\n\
  pi                   Run the sample Spark Pi application\n"
