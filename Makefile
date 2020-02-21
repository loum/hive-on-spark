# Include overrides (must occur before include statements).
MAKESTER__CONTAINER_NAME := hive-on-spark

include makester/makefiles/base.mk
include makester/makefiles/docker.mk

MAKESTER__RUN_COMMAND := $(DOCKER) run --rm -d\
 -p 10000:10000\
 --name $(MAKESTER__CONTAINER_NAME)\
 $(MAKESTER__SERVICE_NAME):$(HASH)

bi: build-image

build-image:
	@$(DOCKER) build -t $(MAKESTER__SERVICE_NAME):$(HASH) .

rmi: rm-image

rm-image:
	@$(DOCKER) rmi $(MAKESTER__SERVICE_NAME):$(HASH) || true

login:
	@$(DOCKER) exec -ti $(MAKESTER__CONTAINER_NAME) su - hdfs

beeline:
	@$(DOCKER) exec -ti $(MAKESTER__CONTAINER_NAME)\
 sh -c "runuser -l hdfs -c 'beeline -u jdbc:hive2://localhost:10000'"

help: base-help docker-help
	@echo "(Makefile)\n\
  build-image:         Build docker image $(MAKESTER__SERVICE_NAME):$(HASH) (alias bi)\n\
  rm-image:            Delete docker image $(MAKESTER__SERVICE_NAME):$(HASH) (alias rmi) \n\
  login:               Login to container $(MAKESTER__CONTAINER_NAME) as user \"hdfs\"\n\
  beeline:             Execute beeline CLI on $(MAKESTER__CONTAINER_NAME) as user \"hdfs\"\n\
	";

.PHONY: help
