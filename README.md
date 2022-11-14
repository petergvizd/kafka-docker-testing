# kafka-docker-testing

Simple kafka setup with running kafka cluster in both kind k8s and as docker containers

Setup of both clusters:
- 3 zookeepers
- 3 brokers with SASL_SSL client authentication
- 1 kafka-producer
- 1 kafka-consumer

Init Setup:
```
security/generate.sh
./prepare-kafka.sh
```

Destruction:
```
./destroy-kafka.sh
security/clean.sh
```
