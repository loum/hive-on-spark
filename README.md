# Hive 3.1.2 on Spark 2.4.8 (on YARN) with Docker
- [Overview](#Overview)
- [Quick Links](#Quick-Links)
- [Quick Start](#Quick-Start)
- [Prerequisites](#Prerequisites)
- [Getting Started](#Getting-Started)
- [Getting Help](#Getting-Help)
- [Docker Image Management](#Docker-Image-Management)
  - [Image Build](#Image-Build)
  - [Image Searches](#Image-Searches)
  - [Image Tagging](#Image-Tagging)
- [Interact with Hive on Spark](#Interact-with-Hive-on-Spark)
  - [Start a shell on the Container](#Start-a-shell-on-the-Container)
  - [Using Beeline CLI (HiveServer2)](#Using-Beeline-CLI-(HiveServer2))
- [Only Need Spark?](#Only-Need-Spark?)
  - [Sample SparkPi Application](#Sample-SparkPi-Application)
  - [`pyspark`](#pyspark)
  - [`spark-shell`](#spark-shell)
- [Web Interfaces](#Web-Interfaces)

## Overview
Quick and easy way to get Hive on Spark (on YARN) with Docker.  See [Apache Hive on Spark docs](https://cwiki.apache.org/confluence/display/Hive/Hive+on+Spark%3A+Getting+Started) for more information.
> **_NOTE:_** Now with [Livy](https://livy.incubator.apache.org/) support.

Lots happening here, but in short this repository will build you a Docker image that allows you to run Hive with Spark as the compute engine.  [Spark itself uses YARN as the resource manager](https://spark.apache.org/docs/2.4.8/running-on-yarn.html) which we leverage from the underlying Hadoop install.  See documentation on the [Hive base Docker image](https://github.com/loum/hadoop-hive) for details on how Hadoop/YARN has been configured.

## Quick Links
- [Apache Hadoop](https://hadoop.apache.org/)
- [Apache Hive](https://hive.apache.org/)
- [Apache Spark](https://spark.apache.org/)
- [Apache Livy](https://livy.incubator.apache.org/)

## Quick Start
Impatient and just want Hive on Spark quickly?
```
docker run --rm -d --name hive-on-spark loum/hive-on-spark:latest
```
## Prerequisties
- [Docker](https://docs.docker.com/install/)
- [GNU make](https://www.gnu.org/software/make/manual/make.html)

## Getting Started
Get the code and change into the top level `git` project directory:
```
git clone https://github.com/loum/hive-on-spark.git && cd hive-on-spark
```
> **_NOTE:_** Run all commands from the top-level directory of the `git` repository.

For first-time setup, get the [Makester project](https://github.com/loum/makester.git):
```
git submodule update --init
```
Keep [Makester project](https://github.com/loum/makester.git) up-to-date with:
```
make submodule-update
```
Setup the environment:
```
make init
```
## Getting Help
There should be a `make` target to get most things done.  Check the help for more information:
```
make help
```
## Docker Image Management
### Image Build
The image build compiles Spark from scratch to ensure we get the correct version without the YARN libraries.  More info can be found at the [Spark build page](http://spark.apache.org/docs/2.4.8/building-spark.html).

To build the Docker image:
```
make build-image
```
### Image Searches
Search for existing Docker image tags with command:
```
make search-image
```
### Image Tagging
By default, `makester` will tag the new Docker image with the current branch hash.  This provides a degree of uniqueness but is not very intuitive.  That's where the `tag-version` `Makefile` target can help.  To apply tag as per project tagging convention `<hive-version>-<spark-version>-<image-release-number>`
```
make tag-version
```
To tag the image as `latest`
```
make tag-latest
```
## Interact with Hive on Spark
To start the container and wait for all Hadoop services to initiate:
```
make controlled-run
```
To stop the container:
```
make stop
```
### Start a shell on the Container
```
make login
```
### Using Beeline CLI (HiveServer2)
> **_NOTE:_** Check the [Beeline Command Reference](https://cwiki.apache.org/confluence/display/Hive/HiveServer2+Clients#HiveServer2Clients-Beeline%E2%80%93CommandLineShell) for more information.

Login to `beeline` (`!q` to exit CLI):
```
make beeline
```
Create a Hive table named `test`:
```
make beeline-create
```
To show tables:
```
make beeline-show
```
To insert a row of data into Hive table `test`

> **_NOTE:_** This will invoke the Spark execution engine through YARN.
```
make beeline-insert
```
To select all rows in Hive table `test`:
```
make beeline-select
```
To drop the Hive table `test`:
```
make beeline-drop
```
Alternatively, port `10000` is exposed to allow connectivity to clients with JDBC.

## Only Need Spark?
The [Spark computing system](<https://spark.apache.org/docs/latest/index.html>)_ is available and can be invoked as per normal.  More information on submitting applications to Spark can be found [here](https://spark.apache.org/docs/2.4.8/submitting-applications.html).

### Sample SparkPi Application
The [sample SparkPi application](https://spark.apache.org/docs/2.4.8/running-on-yarn.html#launching-spark-on-yarn) can be launched with:
```
make pi
```
Apart from some verbose logging displayed on the console it may appear that not much has happened here.  However, since the [Spark application has been deployed in cluster mode](https://spark.apache.org/docs/2.4.8/cluster-overview.html) you will need to dump the associated application ID's log to see meaningful output.  To get a list of Spark application logs (under YARN):
```
make yarn-apps
```
Then plug in an `Application-Id` into:
```
make yarn-app-log YARN_APPLICATION_ID=<Application-Id>
```
To see something similar to the following::
```
====================================================================
LogType:stdout
LogLastModifiedTime:Sat Apr 11 21:49:03 +0000 2020
LogLength:33
LogContents:
Pi is roughly 3.1398156990784956

End of LogType:stdout
***********************************************************************
```
### `pyspark`
```
make pyspark
```
### spark-shell
```
make spark-shell
```
## Web Interfaces
The following web interfaces are available to view configurations and logs and to track YARN/Spark job submissions:
- YARN NameNode web UI: http://localhost:8042
- YARN ResourceManager web UI: http://localhost:8088
- Spark History Server web UI: http://localhost:18080
- HiveServer2 web UI: http://localhost:10002
