#!/bin/bash

set -ex

SCRIPT_PATH=$(dirname -- "$0")
TRUSTSTORE_DIR="$SCRIPT_PATH/truststore"
KEYSTORE_DIR="$SCRIPT_PATH/keystore"
ACTORS=("broker" "client")

for ACTOR in ${ACTORS[@]}; do
	rm -f $SCRIPT_PATH/$ACTOR.*	
done	

rm -f $SCRIPT_PATH/ca.* $SCRIPT_PATH/inter.* $TRUSTSTORE_DIR/*.jks $KEYSTORE_DIR/*.jks
