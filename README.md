# kafka-docker-testing

Simple kafka setup with:
- 3 zookeepers with SASL client authentication
- 3 brokers with SASL_SSL inter broker communication and SASL_SSL client authentication
- 1 kafka-producer
- 1 kafka-consumer

Init Setup:
```
security/generate.sh
docker-compose up
```

Destruction:
```
docker-compose down
security/clean.sh
```
