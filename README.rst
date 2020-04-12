###############################################
Hive 3.1.2 on Spark 2.4.5 (on YARN) with Docker
###############################################

Quick and easy way to get Hive on Spark (on YARN) with Docker.

See `Apache Hive on Spark docs <https://cwiki.apache.org/confluence/display/Hive/Hive+on+Spark%3A+Getting+Started>`_ for more information.

Lots happening here, but in short this repository will build you a Docker image that allows you to run Hive with Spark as the compute engine.  `Spark itself uses YARN as the resource manager <https://spark.apache.org/docs/2.4.5/running-on-yarn.html>`_ which we leverage from the underlying Hadoop install.

See documentation on the underlying `Hive base Docker image <https://github.com/loum/hadoop-hive>`_ for details on how Hadoop/YARN has been configured.

************
Quick Start
************

Impatient and just want Hadoop quickly?::

    $ docker run --rm -ti -d \
     --name hive-on-spark \
     loum/hive-on-spark:latest

*************
Prerequisties
*************

- `Docker <https://docs.docker.com/install/>`_

***************
Getting Started
***************

Get the code and change into the top level ``git`` project directory::

    $ git clone https://github.com/loum/hive-on-spark.git && cd spark-on-hive

.. note::

    Run all commands from the top-level directory of the ``git`` repository.

For first-time setup, get the `Makester project <https://github.com/loum/makester.git>`_::

    $ git submodule update --init

Keep `Makester project <https://github.com/loum/makester.git>`_ up-to-date with::

    $ git submodule update --remote --merge

Setup the environment::

    $ make init

************
Getting Help
************

There should be a ``make`` target to be able to get most things done.  Check the help for more information::

    $ make help

***********
Image Build
***********

The image build actually builds Spark from scratch to ensure we get the correct version without the YARN libraries.  This substationally increaases the image build time.  More info can be found at the `Spark build page <http://spark.apache.org/docs/2.4.5/building-spark.html>`_

To build the Docker image::

    $ make bi

*********
Image Tag
*********

To tag the image as ``latest``::

    $ make tag

Or to apply tagging convention using <hive-version>-<spark-version>-<image-release-number>::

    $ make tag MAKESTER__IMAGE_TAG=3.1.2-2.4.5-1

*******************
Start the Container
*******************

::

    $ make run

To start the container and wait for all Hadoop services to initiate::

    $ make controlled-run

******************************
Start a shell on the Container
******************************

::

    $ make login

***************************
Interact with Hive on Spark
***************************

Using Beeline CLI (HiveServer2)
===============================

Login to ``beeline`` (``!q`` to exit CLI)::

    $ make beeline

Check the `Beeline Command Reference <https://cwiki.apache.org/confluence/display/Hive/HiveServer2+Clients#HiveServer2Clients-Beeline%E2%80%93CommandL
ineShell>`_ for more.

Some other handy commands to run with ``beeline`` via ``make``:

Create a Hive table named ``test``::

    $ make beeline-create

To show tables::

    $ make beeline-show

To insert a row of data into Hive table ``test``

.. note::

    This will invoke the Spark execution engine through YARN.

::

    $ make beeline-insert

To select all rows in Hive table ``test``::

    $ make beeline-select

To drop the Hive table ``test``::

    $ make beeline-drop

Alternatively, port ``10000`` is exposed to allow connectivity to clients with JDBC.

****************
Only Need Spark?
****************

The `Spark computing system <https://spark.apache.org/docs/latest/index.html>`_ is available and can be invoked as per normal.

More information on submitting applications to Spark can be found `here <https://spark.apache.org/docs/2.4.5/submitting-applications.html>`_

Sample SparkPi Application
==========================

The `sample SparkPi application <https://spark.apache.org/docs/2.4.5/running-on-yarn.html#launching-spark-on-yarn>`_ can be launched with::

    $ make pi

Apart from some verbose logging displayed on the console it may appear that not much has happened here.  However, since the `Spark application has been deployed in cluster mode <https://spark.apache.org/docs/2.4.5/cluster-overview.html>`_ you will need to dump the associated application ID's log to see meaningful output.

To get a list of Spark application logs (under YARN)::

    $ make yarn-apps

Then plug in an ``Application-Id`` into::

    $ make yarn-app-log YARN_APPLICATION_ID=<Application-Id>

To see something similar to the following::

    ====================================================================
    LogType:stdout
    LogLastModifiedTime:Sat Apr 11 21:49:03 +0000 2020
    LogLength:33
    LogContents:
    Pi is roughly 3.1398156990784956
    
    End of LogType:stdout
    ***********************************************************************

``pyspark``
===========

::

    $ make pyspark 

``spark-shell``
===============

::

    $ make spark-shell

**************
Web Interfaces
**************

The following web interfaces are available to view configurations and logs and to track YARN/Spark job submissions:

- YARN NameNode web UI

  - `<http://localhost:8042>`_

- YARN ResourceManager web UI

  - `<http://localhost:8088>`_

- `Spark History Server web UI <https://spark.apache.org/docs/2.4.5/monitoring.html>`_

  - `<http://localhost:18080>`_

- `HiveServer2 web UI <https://cwiki.apache.org/confluence/display/Hive/Setting+Up+HiveServer2#SettingUpHiveServer2-WebUIforHiveServer2>`_

  - `<http://localhost:10002>`_

******************
Stop the Container
******************

::

    $ make stop
