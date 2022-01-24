# ------------------------------ ATLAS CODE COMPILE STAGE ------------------------------
FROM maven:3.8.4-openjdk-8 AS atlas_compile

LABEL maintainer="Hritvik Patel <hritvik.patel4@gmail.com>"

ENV ATLAS_VERSION 2.2.0

RUN apt-get update && \
    apt-get -y upgrade && \
    apt-get -y install apt-utils patch python && \
    cd /tmp && \
    wget --retry-connrefused -O apache-atlas-$ATLAS_VERSION-sources.tar.gz https://downloads.apache.org/atlas/$ATLAS_VERSION/apache-atlas-$ATLAS_VERSION-sources.tar.gz && \
    mkdir -p /tmp/atlas-src && \
    tar xzf /tmp/apache-atlas-$ATLAS_VERSION-sources.tar.gz -C /tmp/atlas-src --strip 1 && \
    rm -rf /tmp/apache-atlas-$ATLAS_VERSION-sources.tar.gz

COPY patches/* /tmp/atlas-src

RUN cd /tmp/atlas-src && \
    patch -u -b pom.xml -i log4j.patch && \
    patch -u -b webapp/src/main/java/org/apache/atlas/web/filters/AtlasAuthenticationFilter.java -i deprecateNDC.patch && \
    rm log4j.patch && \
    rm deprecateNDC.patch && \
    sed -i "s/http:\/\/repo1.maven.org\/maven2/https:\/\/repo1.maven.org\/maven2/g" pom.xml && \
    export MAVEN_OPTS="-Xms2g -Xmx4g" && \
    mvn clean -Dhttps.protocols=TLSv1.2 package -Pdist
    # Add option '-DskipTests' to skip unit and integration tests
    # mvn clean -Dhttps.protocols=TLSv1.2 -DskipTests package -Pdist

# ------------------------------ ATLAS IMAGE CREATION STAGE ------------------------------
FROM ubuntu:bionic

LABEL maintainer="Hritvik Patel <hritvik.patel4@gmail.com>"

ENV ATLAS_VERSION 2.2.0
ENV ATLAS_INSTALL_LOCATION /opt/apache-atlas-$ATLAS_VERSION

COPY --from=atlas_compile /tmp/atlas-src/distro/target/apache-atlas-$ATLAS_VERSION-hive-hook.tar.gz /tmp
COPY --from=atlas_compile /tmp/atlas-src/distro/target/apache-atlas-$ATLAS_VERSION-kafka-hook.tar.gz /tmp
COPY --from=atlas_compile /tmp/atlas-src/distro/target/apache-atlas-$ATLAS_VERSION-server.tar.gz /tmp

RUN apt-get update && \
    apt-get -y upgrade && \
    apt-get -y install curl openjdk-8-jdk patch python unzip && \
    tar xzf /tmp/apache-atlas-$ATLAS_VERSION-hive-hook.tar.gz   -C /opt && \
    tar xzf /tmp/apache-atlas-$ATLAS_VERSION-kafka-hook.tar.gz  -C /opt && \
    tar xzf /tmp/apache-atlas-$ATLAS_VERSION-server.tar.gz      -C /opt && \
    cp -R /opt/apache-atlas-hive-hook-$ATLAS_VERSION/*  $ATLAS_INSTALL_LOCATION && \
    cp -R /opt/apache-atlas-kafka-hook-$ATLAS_VERSION/* $ATLAS_INSTALL_LOCATION && \
    mkdir -p $ATLAS_INSTALL_LOCATION/conf/patches && \
    echo $ATLAS_VERSION > $ATLAS_INSTALL_LOCATION/version.txt && \
    rm -rf /opt/apache-atlas-hive-hook-$ATLAS_VERSION /opt/apache-atlas-kafka-hook-$ATLAS_VERSION && \
    rm -rf /tmp/* && \
    rm -rf /var/lib/apt/lists/*

ENV HBASE_CONF_DIR $ATLAS_INSTALL_LOCATION/conf/hbase
ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64
ENV PATH $PATH:$JAVA_HOME/bin

COPY patches/* $ATLAS_INSTALL_LOCATION/conf/patches
COPY conf/* $ATLAS_INSTALL_LOCATION/conf
COPY docker_entrypoint.sh /

RUN chmod +x /docker_entrypoint.sh

EXPOSE 21000

VOLUME ["$ATLAS_INSTALL_LOCATION/conf", "$ATLAS_INSTALL_LOCATION/data", "$ATLAS_INSTALL_LOCATION/logs"]

ENTRYPOINT ["/docker_entrypoint.sh"]
