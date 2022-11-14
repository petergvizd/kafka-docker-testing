#!/bin/bash

set -ex

SCRIPT_PATH=$(dirname -- "$0")
TRUSTSTORE_DIR="$SCRIPT_PATH/truststore"
KEYSTORE_DIR="$SCRIPT_PATH/keystore"
ACTORS=("broker" "client")

for ACTOR in ${ACTORS[@]}; do
	rm -f $SCRIPT_PATH/$ACTOR.*	
done	

rm -f $SCRIPT_PATH/ca.* $SCRIPT_PATH/inter.* $SCRIPT_PATH/full.* $SCRIPT_PATH/.srl $TRUSTSTORE_DIR/*.jks $TRUSTSTORE_DIR/*.p12 $KEYSTORE_DIR/*.jks $KEYSTORE_DIR/*.p12

KUBERNETES_DIR=$(echo "$SCRIPT_PATH/../kubernetes")
for TMPL_FILE in $KUBERNETES_DIR/*/*.tmpl; do
    if [ -d "$TMPL_FILE" ]; then
    	continue
    fi
    if [ -f ${TMPL_FILE%.*} ]; then
    	rm ${TMPL_FILE%.*}
    fi
done
