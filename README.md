# kafka-docker-testing

**This project is initial PoC for migration kafka to kubernetes.**

### Certificates keystores and truststores
First of all we need to generate certificates keystores and truststores. 
For this purpose is there bash script `security/generate.sh` that will create:
* CA certificate `ca.crt`
* Intermediate certificate and key `inter.crt, inter.key`
* Chain of CA and intermediate certificate in PEM and PKCS12 `full.crt` and `full.p12`
* keystores and truststores for brokers `broker-1, broker-2, broker-3` called `keystore/broker-[123].jks` and `truststore/broker-[123].jks`
* keystore and trustore for client connection in both JKS and PKCS12 `keystore/client.[jks|p12]` and `trustore/client.[jks|p12]`
* password for all keystores and truststores is `password`

### Current solution in docker containers
To simulate our current solution there is prepared docker-compose file that contains:
* 3 zookeepers 
  * hostnames and container names: `zookeeper-1, zookeeper-2, zookeeper-2`
  * version 3.6.3
  * plaintext listener on port 2181
  * SASL authentication with user `admin:adminadmin`
* kafka-admin service
  * simple service for creation admin of kafka admin password in zookeeper with SCRAM-SHA-512
* 3 kafka brokers
  * hostnames and container names: `broker-1, broker-2, broker-3`
  * version 2.8.0
  * SASL_SSL listener on port 9091 with required mTLS client authentication
  * inter broker SASL_SSL listener
  * enabled ACL authorization
  * Super user `admin:adminadmin`
  * other kafka config options can be specified via env variabled KAFKA_CFG_
* kafka-docker-producer, kafka-docker-consumer service
  * simple infinite producer and consumer using topic test
  * consumer uses consumer group test
  * both using prepared keystore and trustore for SSL connection to brokers
  * both authenticated via user `client:clientclient`

**Before spawning kafka-docker-producer, kafka-docker-consumer service, first test topic and client user must be created.
For this purpose is used strimzi-topic-operator and strimzi-user-operator running in kind k8s.**

### Preparing local kind k8s cluster
    
For running strimzi-topic-operator, strimzi-user-operator and kafka in k8s in used local k8s cluster running as kind docker container.
To create local kind k8s cluster just run: 

```kind create cluster --name kafka --image=kindest/node:v1.20.15```

Kind container is going to have hostname and container name `kafka-control-plane` so
for connecting it to same docker network as containers from docker-compose are running just execute

```docker network connect kafka-docker kafka-control-plane```

After that we can install necessary helm-charts for testing:
* cert-manager in version v1.5.3
```
helm repo add jetstack https://charts.jetstack.io
helm repo update
helm upgrade --install cert-manager jetstack/cert-manager -n kube-system --version v1.5.3 --set installCRDs=true --kube-context kind-kafka
```
* prometheus in version 15.14.0
```
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm upgrade --install prometheus prometheus-community/prometheus -n monitoring --create-namespace --version 15.14.0 --values $SCRIPT_PATH/prometheus.yaml --kube-context kind-kafka
```
* strimzi-kafka-operator in version 0.27.1
```
helm repo add strimzi https://strimzi.io/charts
helm repo update
helm upgrade --install strimzi-kafka-operator strimzi/strimzi-kafka-operator -n kafka-k8s --create-namespace --version 0.27.1 --kube-context kind-kafka
```

### Managing topics users and ACLs from k8s
As mentioned above for managing topics, users and ACLs in kafka running in docker containers we can use:
* strimzi-topic-operator (already used in production)
* strimzi-user-operator

For running both in local kind cluster there are prepared objects in `kubernetes/kafka-docker` with following objects:
* `namespace` - named `kafka-docker`
* `serviceaccount` - named `strimzi-entity-operator`
* `clusterrolebinding` - for binding ClusterRole `strimzi-entity-operator` to ServiceAccount `strimzi-entity-operator`
* `client-store-secret` - client keystore and truststore
* `client-store-password-secret` - password to client keystore and truststore
* `topic-operator-deployment` - for managing kafka topics in kafka-docker https://strimzi.io/docs/operators/latest/deploying.html#deploying-the-topic-operator-standalone-str
* `user-operator-deployment` - for managing kafka topics in kafka-docker https://strimzi.io/docs/operators/latest/deploying.html#deploying-the-user-operator-standalone-str
* `kafkatopic` - named `test`
* `kafkauser` - named `client`

After this setup you should be able to successfully start `kafka-docker-producer` and `kafka-docker-consumer` docker compose service.

### Running kafka in k8s
For spinning up kafka cluster in kind k8s there should be already running strimzi-cluster-operator in namespace `kafka-k8s`,
and other necessary objects are located in `kubernetes/kafka-k8s`:
* `kafka-ca-secret` - custom CA authority for kafka cluster https://strimzi.io/docs/operators/latest/configuring.html#installing-your-own-ca-certificates-str
* `kafka` - definition for kafka cluster
  * version 2.8.0
  * 3 brokers 3 zookeepers
  * config section with customised broker settings
  * SASL_SSL listener on local port 9092 and exposed as nodeport on 300092
  * SCRAM-SHA-512 SASL authentication
  * 1 GB storage
  * bound with topic and user operator
* `kafkatopic` - named `test`
* `kafkauser` - named `client`

After this setup you should be able to successfully start `kafka-k8s-producer` and `kafka-k8s-consumer` docker compose service,
that are exact copies of `kafka-docker-producer` and `kafka-docker-consumer` with change only in `--bootstrap-server` param pointing to `kafka-control-plane:30092`.

### 2 Steps setup
For spinning up eveything in two steps it should be enough to run:
```
security/generate.sh
./prepare-kafka.sh
```

and for destruction:
```
./destroy-kafka.sh
security/clean.sh
```
