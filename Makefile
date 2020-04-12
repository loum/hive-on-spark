# Include overrides (must occur before include statements).
MAKESTER__REPO_NAME := loum
MAKESTER__CONTAINER_NAME := hive-on-spark

include makester/makefiles/base.mk
include makester/makefiles/docker.mk
include makester/makefiles/python-venv.mk

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

init: makester-requirements

bi: build-image

build-image:
	@$(DOCKER) build -t $(MAKESTER__SERVICE_NAME):$(HASH) .

rmi: rm-image

rm-image:
	@$(DOCKER) rmi $(MAKESTER__SERVICE_NAME):$(HASH) || true

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

pi:
	@$(DOCKER) exec $(MAKESTER__CONTAINER_NAME) bash -c\
 "HADOOP_CONF_DIR=/opt/hadoop/etc/hadoop /opt/spark/bin/spark-submit --class org.apache.spark.examples.SparkPi\
 --files /opt/spark/conf/metrics.properties.template\
 --master yarn\
 --deploy-mode cluster\
 --driver-memory 1g\
 --executor-memory 1g\
 --executor-cores 1\
 /opt/spark/examples/jars/spark-examples_2.11-2.4.5.jar"

yarn-apps:
	@$(DOCKER) exec -ti $(MAKESTER__CONTAINER_NAME)\
 bash -c "/opt/hadoop/bin/yarn application -list -appStates ALL"

yarn-app-log:
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

help: base-help docker-help python-venv-help
	@echo "(Makefile)\n\
  build-image:         Build docker image $(MAKESTER__SERVICE_NAME):$(HASH) (alias bi)\n\
  rm-image:            Delete docker image $(MAKESTER__SERVICE_NAME):$(HASH) (alias rmi) \n\
  login:               Login to container $(MAKESTER__CONTAINER_NAME) as user \"hdfs\"\n\
  yarn-apps:           List all YARN application IDs\n\
  yarn-app-log:        Dump log for YARN application ID defined by \"YARN_APPLICATION_ID\"\n\
  beeline:             Start beeline CLI on $(MAKESTER__CONTAINER_NAME)\n\
  beeline-create:      Execute beeline command \"CREATE TABLE ...\" on $(MAKESTER__CONTAINER_NAME)\n\
  beeline-show:        Execute beeline command \"SHOW TABLES\" on $(MAKESTER__CONTAINER_NAME)\n\
  beeline-insert:      Execute beeline command \"INSERT INTO TABLE ...\" on $(MAKESTER__CONTAINER_NAME)\n\
  beeline-select:      Execute beeline command \"SELECT * FROM ...\" on $(MAKESTER__CONTAINER_NAME)\n\
  beeline-drop:        Execute beeline command \"DROP TABLE ...\" on $(MAKESTER__CONTAINER_NAME)\n\
  pi:                  Run the sample Spark Pi application\n\
	";

.PHONY: help
