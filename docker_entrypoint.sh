#!/usr/bin/env bash

ATLAS_VERSION=2.2.0
ATLAS_PROPERTIES_FILE=$ATLAS_INSTALL_LOCATION/conf/atlas-application.properties

# sed -i -e "s/HBASE_TABLE/$HBASE_TABLE/" $ATLAS_PROPERTIES_FILE
# sed -i -e "s/ZK_QUORUM/$ZK_QUORUM/" $ATLAS_PROPERTIES_FILE
# sed -i -e "s/KAFKA_BOOTSTRAP_SERVERS/$KAFKA_BOOTSTRAP_SERVERS/" $ATLAS_PROPERTIES_FILE
# sed -i -e "s/HOSTNAME/$HOSTNAME/" $ATLAS_PROPERTIES_FILE

usage(){
    echo "-----------------------------------------------------------------"
    echo "USAGE: must specify one of: cold_start/hot_start [--ha], bash, sh"
    echo "-----------------------------------------------------------------"
}

setup_properties(){
    sed -i -e "s/HBASE_TABLE/$HBASE_TABLE/" $ATLAS_PROPERTIES_FILE
    sed -i -e "s/HBASE_ZK_QUORUM/$HBASE_ZK_QUORUM/" $ATLAS_PROPERTIES_FILE
    sed -i -e "s/SOLR_ZK_QUORUM/$SOLR_ZK_QUORUM/" $ATLAS_PROPERTIES_FILE
    sed -i -e "s/KAFKA_ZK_QUORUM/$KAFKA_ZK_QUORUM/" $ATLAS_PROPERTIES_FILE
    sed -i -e "s/KAFKA_BOOTSTRAP_SERVERS/$KAFKA_BOOTSTRAP_SERVERS/" $ATLAS_PROPERTIES_FILE
    sed -i -e "s/HOSTNAME/$HOSTNAME/" $ATLAS_PROPERTIES_FILE
}

start_atlas(){
    echo "--------------------------------------------------------"
    echo "-------------------- Starting Atlas --------------------"
    echo "--------------------------------------------------------"

    $ATLAS_INSTALL_LOCATION/bin/atlas_start.py
    sleep 45
    tail -f $ATLAS_INSTALL_LOCATION/logs/application.log
}

if [ -n "$*" ]; then
    if [ "$1" = cold_start ]; then
        if [[ $* == *--ha* ]]; then
            echo "--------------------------------------------------------"
            echo "-------------------- HA flag passed --------------------"
            echo "--------------------------------------------------------"
            patch -u -b $ATLAS_PROPERTIES_FILE -i $ATLAS_INSTALL_LOCATION/conf/atlas_HA_conf.patch

            sed -i -e "s/SERVER1_ADDR/$SERVER1_ADDR/" $ATLAS_PROPERTIES_FILE
            sed -i -e "s/SERVER2_ADDR/$SERVER2_ADDR/" $ATLAS_PROPERTIES_FILE
        fi

        setup_properties

        echo "--------------------------------------------------------"
        echo "Using properties from $ATLAS_PROPERTIES_FILE"
        echo "--------------------------------------------------------"
        cat $ATLAS_PROPERTIES_FILE
        echo "--------------------------------------------------------"
        
        echo "Sleeping for 90 seconds"
        sleep 90
        echo "--------------------------------------------------------"
        
        echo "Creating vertex_index in Solr"
        curl -X GET "http://$SOLR_HOST:$SOLR_PORT/solr/admin/collections?action=CREATE&name=vertex_index&numShards=1&replicationFactor=1&collection.configName=_default"
        echo "--------------------------------------------------------"
        
        echo "Creating edge_index in Solr"
        curl -X GET "http://$SOLR_HOST:$SOLR_PORT/solr/admin/collections?action=CREATE&name=edge_index&numShards=1&replicationFactor=1&collection.configName=_default"
        echo "--------------------------------------------------------"
        
        echo "Creating fulltext_index in Solr"
        curl -X GET "http://$SOLR_HOST:$SOLR_PORT/solr/admin/collections?action=CREATE&name=fulltext_index&numShards=1&replicationFactor=1&collection.configName=_default"
        echo "--------------------------------------------------------"
        
        start_atlas
    elif [ "$1" = hot_start ]; then
        if [[ $* == *--ha* ]]; then
            echo "--------------------------------------------------------"
            echo "-------------------- HA flag passed --------------------"
            echo "--------------------------------------------------------"
            patch -u -b $ATLAS_PROPERTIES_FILE -i $ATLAS_INSTALL_LOCATION/conf/atlas_HA_conf.patch

            sed -i -e "s/SERVER1_ADDR/$SERVER1_ADDR/" $ATLAS_PROPERTIES_FILE
            sed -i -e "s/SERVER2_ADDR/$SERVER2_ADDR/" $ATLAS_PROPERTIES_FILE
        fi

        setup_properties

        echo "--------------------------------------------------------"
        echo "Using properties from $ATLAS_PROPERTIES_FILE"
        echo "--------------------------------------------------------"
        cat $ATLAS_PROPERTIES_FILE
        echo "--------------------------------------------------------"
        
        echo "Sleeping for 90 seconds"
        sleep 90
        echo "--------------------------------------------------------"

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
