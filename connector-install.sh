#!/bin/bash
docker exec -i connect confluent-hub install confluentinc/kafka-connect-azure-service-bus:1.2.7 --component-dir /usr/share/java --no-prompt
docker-compose restart connect