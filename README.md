[![Atlas version](https://img.shields.io/badge/Atlas-2.2.0-green.svg)](https://github.com/hritvikpatel4/apache-atlas-docker)
![GitHub](https://img.shields.io/github/license/hritvikpatel4/apache-atlas-docker)
![GitHub Workflow Status (branch)](https://img.shields.io/github/workflow/status/hritvikpatel4/apache-atlas-docker/Apache%20Atlas%20Docker%20Image/master)
[![Docker Pulls](https://img.shields.io/docker/pulls/ntwine/apache-atlas.svg)](https://hub.docker.com/repository/docker/ntwine/apache-atlas)
![Docker Image Size (latest by date)](https://img.shields.io/docker/image-size/ntwine/apache-atlas)

Apache Atlas Docker image
=========================

This `Apache Atlas` image is built from the 2.2.0-release source tarball and patched (including the fix for Log4JShell CVE) to be run in a Docker container.

This image is configured to connect to Hbase and Solr that are running on separate machines or docker containers. This image needs the initialization step before you can use it.

If you want to configure the docker image, use [the documentation](https://atlas.apache.org/#/Configuration).

Basic usage
-----------

1. Pull the latest release image:
```bash
docker pull ntwine/apache-atlas:master
```
or
```bash
docker pull ghcr.io/hritvikpatel4/apache-atlas:master
```

2. Start Apache Atlas in a container exposing Web-UI port 21000:
```bash
docker run -d \
    -p 21000:80 \
    --name atlas \
    -e HBASE_TABLE=apache_atlas_janus \
    -e ZK_QUORUM=zookeeper:2181 \
    -e KAFKA_BOOTSTRAP_SERVERS=broker:9092 \
    -e HOSTNAME=atlas \
    -e SOLR_HOST=solr \
    -e SOLR_PORT=8983 \
    ntwine/apache-atlas:master \
    atlas_start
```

Please, take into account that the first startup of Atlas may take up to few mins depending on host machine performance before web-interface become available at `http://localhost:21000/`

Web-UI default credentials: `admin / admin`

Usage options
-------------

Gracefully stop Atlas:
```bash
docker exec -it atlas /opt/apache-atlas-2.2.0/bin/atlas_stop.py
```

Check Atlas startup script output:
```bash
docker logs atlas
```

Check interactively Atlas application.log (useful at the first run and for debugging during workload):
```bash
docker exec -it atlas tail -f /opt/apache-atlas-2.2.0/logs/application.log
```

Start Atlas overriding settings by environment variables 
(to support large number of metadata objects for example):
```bash
docker run -d \
    -e "ATLAS_SERVER_OPTS=-server -XX:SoftRefLRUPolicyMSPerMB=0 \
    -XX:+CMSClassUnloadingEnabled -XX:+UseConcMarkSweepGC \
    -XX:+CMSParallelRemarkEnabled -XX:+PrintTenuringDistribution \
    -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=dumps/atlas_server.hprof \
    -Xloggc:logs/gc-worker.log -verbose:gc -XX:+UseGCLogFileRotation \
    -XX:NumberOfGCLogFiles=10 -XX:GCLogFileSize=1m -XX:+PrintGCDetails \
    -XX:+PrintHeapAtGC -XX:+PrintGCTimeStamps" \
    -e HBASE_TABLE=apache_atlas_janus \
    -e ZK_QUORUM=zookeeper:2181 \
    -e KAFKA_BOOTSTRAP_SERVERS=broker:9092 \
    -e HOSTNAME=atlas \
    -e SOLR_HOST=solr \
    -e SOLR_PORT=8983 \
    -p 21000:80 \
    --name atlas \
    ntwine/apache-atlas:master \
    atlas_start
```

Environment Variables
---------------------

The following environment variables are available for configuration:
| Name | Default | Description |
|------|---------|-------------|
| JAVA_HOME | /usr/lib/jvm/java-8-openjdk-amd64 | The java implementation to use. If JAVA_HOME is not found we expect java and jar to be in path
| ATLAS_OPTS | <none> | any additional java opts you want to set. This will apply to both client and server operations
| ATLAS_CLIENT_OPTS | <none> | any additional java opts that you want to set for client only
| ATLAS_CLIENT_HEAP | <none> | java heap size we want to set for the client. Default is 1024MB
| ATLAS_SERVER_OPTS | <none> |  any additional opts you want to set for atlas service.
| ATLAS_SERVER_HEAP | <none> | java heap size we want to set for the atlas server. Default is 1024MB
| ATLAS_HOME_DIR | <none> | What is is considered as atlas home dir. Default is the base location of the installed software
| ATLAS_LOG_DIR | <none> | Where log files are stored. Defatult is logs directory under the base install location
| ATLAS_PID_DIR | <none> | Where pid files are stored. Defatult is logs directory under the base install location
| ATLAS_EXPANDED_WEBAPP_DIR | <none> | Where do you want to expand the war file. By Default it is in /server/webapp dir under the base install dir.

Bug Tracker
-----------

Bugs are tracked on [GitHub Issues](https://github.com/hritvikpatel4/apache-atlas-docker/issues).
In case of trouble, please check there to see if your issue has already been reported.
If you spotted it first, help us smash it by providing detailed and welcomed feedback.

Maintainer
----------

This image is maintained by [Hritvik Patel](mailto:hritvik.patel4@gmail.com)
* https://github.com/hritvikpatel4/apache-atlas-docker
