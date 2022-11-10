#!/bin/bash

set -ex

SCRIPT_PATH=$(dirname -- "$0")
TRUSTSTORE_DIR="$SCRIPT_PATH/truststore"
KEYSTORE_DIR="$SCRIPT_PATH/keystore"
STORE_PASSWORD="password"
VALIDITY_DAYS=3650
SUBJECT="/C=CZ/ST=Brno/L=Brno/O=Test/OU=Test/CN="
CA_KEY_FILE="$SCRIPT_PATH/ca.key"
CA_CERT_FILE="$SCRIPT_PATH/ca.crt"
CA_CN="ca"
INTER_KEY_FILE="$SCRIPT_PATH/inter.key" 
INTER_CSR_FILE="$SCRIPT_PATH/inter.csr"
INTER_CERT_FILE="$SCRIPT_PATH/inter.crt"
INTER_CN="inter"
INTER_CERT_EXTENSIONS="[v3_ca]\nbasicConstraints=CA:TRUE,pathlen:0"
INTER_EXT_FILE=$SCRIPT_PATH/inter.ext
ACTORS=("broker-1" "broker-2" "broker-3" "client")

openssl req -nodes -new -x509 -keyout $CA_KEY_FILE -out $CA_CERT_FILE -days $VALIDITY_DAYS -subj "$SUBJECT$CA_CN" -addext basicConstraints=critical,CA:TRUE,pathlen:1

openssl req -nodes -newkey rsa:2048 -keyout $INTER_KEY_FILE -out $INTER_CSR_FILE -subj "$SUBJECT$INTER_CN"
echo -e $INTER_CERT_EXTENSIONS > $INTER_EXT_FILE
openssl x509 -req -CA $CA_CERT_FILE -CAkey $CA_KEY_FILE -in $INTER_CSR_FILE -out $INTER_CERT_FILE -days $VALIDITY_DAYS -CAcreateserial -extensions v3_ca -extfile $INTER_EXT_FILE
rm $INTER_EXT_FILE

for ACTOR in ${ACTORS[@]}; do
	ACTOR_KEY_FILE="$SCRIPT_PATH/$ACTOR.key"
	ACTOR_CSR_FILE="$SCRIPT_PATH/$ACTOR.csr"
	ACTOR_CERT_FILE="$SCRIPT_PATH/$ACTOR.crt"
	ACTOR_PKCS12="$SCRIPT_PATH/$ACTOR.p12"
	ACTOR_KEYSTORE="$KEYSTORE_DIR/$ACTOR.jks"
	ACTOR_TRUSTSTORE="$TRUSTSTORE_DIR/$ACTOR.jks"
	ALL_CERT_FILE="$SCRIPT_PATH/$ACTOR.all.crt"

	openssl req -newkey rsa:2048 -keyout $ACTOR_KEY_FILE -out $ACTOR_CSR_FILE -subj "$SUBJECT$ACTOR" -passout "pass:$STORE_PASSWORD"
	openssl x509 -req -CA $INTER_CERT_FILE -CAkey $INTER_KEY_FILE -in $ACTOR_CSR_FILE -out $ACTOR_CERT_FILE -days $VALIDITY_DAYS -CAcreateserial

	openssl verify -CAfile $CA_CERT_FILE -untrusted $INTER_CERT_FILE $ACTOR_CERT_FILE

	cat $ACTOR_CERT_FILE $INTER_CERT_FILE $CA_CERT_FILE > $ALL_CERT_FILE
	openssl pkcs12 -nodes -export -in $ALL_CERT_FILE -inkey $ACTOR_KEY_FILE -certfile $ALL_CERT_FILE -out $ACTOR_PKCS12 -passin "pass:$STORE_PASSWORD" -passout "pass:$STORE_PASSWORD"

	mkdir -p $KEYSTORE_DIR
	keytool -importkeystore -srckeystore $ACTOR_PKCS12 -srcstoretype pkcs12 -destkeystore $ACTOR_KEYSTORE -deststoretype JKS -deststorepass $STORE_PASSWORD -srcstorepass $STORE_PASSWORD

	mkdir -p $TRUSTSTORE_DIR
	keytool -keystore $ACTOR_TRUSTSTORE -import -alias $CA_CN -file $CA_CERT_FILE -deststoretype JKS -deststorepass $STORE_PASSWORD -noprompt

	rm $SCRIPT_PATH/$ACTOR.* 
done

rm $CA_KEY_FILE $INTER_CSR_FILE $SCRIPT_PATH/*.srl
