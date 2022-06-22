#!/usr/bin/env bash

ATLAS_VERSION=2.2.0
ATLAS_PROPERTIES_FILE=$ATLAS_INSTALL_LOCATION/conf/atlas-application.properties

usage(){
    echo "-----------------------------------------------------------------"
    echo "USAGE: must specify one of: atlas_start [--ha], bash, sh"
    echo "-----------------------------------------------------------------"
}

setup_properties(){
    sed -i -e "s/HBASE_TABLE/$HBASE_TABLE/" $ATLAS_PROPERTIES_FILE
    sed -i -e "s/HBASE_ZK_QUORUM/$HBASE_ZK_QUORUM/" $ATLAS_PROPERTIES_FILE
    sed -i -e "s/SOLR_ZK_QUORUM/$SOLR_ZK_QUORUM/" $ATLAS_PROPERTIES_FILE
    sed -i -e "s/KAFKA_ZK_QUORUM/$KAFKA_ZK_QUORUM/" $ATLAS_PROPERTIES_FILE
    sed -i -e "s/KAFKA_BOOTSTRAP_SERVERS/$KAFKA_BOOTSTRAP_SERVERS/" $ATLAS_PROPERTIES_FILE
    sed -i -e "s/HOSTNAME/$HOSTNAME/" $ATLAS_PROPERTIES_FILE
    sed -i -e "s/GRAPH_STORAGE_LOCK_WAIT_TIME/$GRAPH_STORAGE_LOCK_WAIT_TIME/" $ATLAS_PROPERTIES_FILE
    sed -i -e "s/SOLR_ZOOKEEPER_CONNECT_TIMEOUT/$SOLR_ZOOKEEPER_CONNECT_TIMEOUT/" $ATLAS_PROPERTIES_FILE
    sed -i -e "s/SOLR_ZOOKEEPER_SESSION_TIMEOUT/$SOLR_ZOOKEEPER_SESSION_TIMEOUT/" $ATLAS_PROPERTIES_FILE
    sed -i -e "s/KAFKA_ZOOKEEPER_SESSION_TIMEOUT/$KAFKA_ZOOKEEPER_SESSION_TIMEOUT/" $ATLAS_PROPERTIES_FILE
    sed -i -e "s/KAFKA_ZOOKEEPER_CONNECTION_TIMEOUT/$KAFKA_ZOOKEEPER_CONNECTION_TIMEOUT/" $ATLAS_PROPERTIES_FILE
    sed -i -e "s/KAFKA_ZOOKEEPER_SYNC_TIME/$KAFKA_ZOOKEEPER_SYNC_TIME/" $ATLAS_PROPERTIES_FILE
    sed -i -e "s/KAFKA_AUTO_COMMIT_INTERVAL/$KAFKA_AUTO_COMMIT_INTERVAL/" $ATLAS_PROPERTIES_FILE
    sed -i -e "s/AUDIT_ZOOKEEPER_SESSION_TIMEOUT/$AUDIT_ZOOKEEPER_SESSION_TIMEOUT/" $ATLAS_PROPERTIES_FILE
}

start_atlas(){
    echo "--------------------------------------------------------"
    echo "-------------------- Starting Atlas --------------------"
    echo "--------------------------------------------------------"

    $ATLAS_INSTALL_LOCATION/bin/atlas_start.py

    echo "Sleeping for 120 seconds"
    sleep 120
    echo "--------------------------------------------------------"
    
    tail -f $ATLAS_INSTALL_LOCATION/logs/application.log
}

create_solr_indices(){
    echo "Creating vertex_index in Solr"
    curl -X GET "http://$SOLR_HOST:$SOLR_PORT/solr/admin/collections?action=CREATE&name=vertex_index&numShards=1&replicationFactor=1&collection.configName=_default"
    echo "--------------------------------------------------------"

    echo "Creating edge_index in Solr"
    curl -X GET "http://$SOLR_HOST:$SOLR_PORT/solr/admin/collections?action=CREATE&name=edge_index&numShards=1&replicationFactor=1&collection.configName=_default"
    echo "--------------------------------------------------------"

    echo "Creating fulltext_index in Solr"
    curl -X GET "http://$SOLR_HOST:$SOLR_PORT/solr/admin/collections?action=CREATE&name=fulltext_index&numShards=1&replicationFactor=1&collection.configName=_default"
    echo "--------------------------------------------------------"
}

if [ -n "$*" ]; then
    if [ "$1" = atlas_start ]; then
        if [[ $* == *--ha* ]]; then
            echo "--------------------------------------------------------"
            echo "-------------------- HA flag passed --------------------"
            echo "--------------------------------------------------------"
            patch -u -b $ATLAS_PROPERTIES_FILE -i $ATLAS_INSTALL_LOCATION/conf/patches/atlas_HA_conf.patch

            LOCALHOST_NAME="$(hostname):21000"

            sed -i -e "s/ATLAS_ZK_QUORUM/$ATLAS_ZK_QUORUM/" $ATLAS_PROPERTIES_FILE
            # sed -i -e "s/SERVER1_ADDR/$SERVER1_ADDR/" $ATLAS_PROPERTIES_FILE
            sed -i -e "s/SERVER1_ADDR/$LOCALHOST_NAME/" $ATLAS_PROPERTIES_FILE
            # sed -i -e "s/SERVER2_ADDR/$SERVER2_ADDR/" $ATLAS_PROPERTIES_FILE
            sed -i -e "s/SERVER2_ADDR/$SERVER_ADDR/" $ATLAS_PROPERTIES_FILE

            sed -i -e "s/HA_ZOOKEEPER_RETRY_SLEEPTIME/$HA_ZOOKEEPER_RETRY_SLEEPTIME/" $ATLAS_PROPERTIES_FILE
            sed -i -e "s/HA_ZOOKEEPER_SESSION_TIMEOUT/$HA_ZOOKEEPER_SESSION_TIMEOUT/" $ATLAS_PROPERTIES_FILE
            sed -i -e "s/CLIENT_HA_SLEEP_INTERVAL/$CLIENT_HA_SLEEP_INTERVAL/" $ATLAS_PROPERTIES_FILE
        fi

        setup_properties

        echo "--------------------------------------------------------"
        echo "Using properties from $ATLAS_PROPERTIES_FILE"
        echo "--------------------------------------------------------"
        cat $ATLAS_PROPERTIES_FILE
        echo "--------------------------------------------------------"

        if [ "${CREATE_SOLR_INDICES,,}" = yes ] || [ "${CREATE_SOLR_INDICES,,}" = y ] || [ "${CREATE_SOLR_INDICES,,}" = true ]; then
            create_solr_indices
        fi
        
        start_atlas
    elif [ "$1" = bash ]; then
        bash
    elif [ "$1" = sh ]; then
        sh
    else
        usage
    fi
else
    usage
fi

tail -f /dev/null
wait || :
