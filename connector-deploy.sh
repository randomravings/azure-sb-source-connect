#!/bin/bash
curl -X PUT \
      -H 'Content-Type: application/json' \
      --data "{
            \"connector.class\": \"io.confluent.connect.azure.servicebus.ServiceBusSourceConnector\",
            \"tasks.max\": \"1\",
            \"kafka.topic\":\"input-topic\",
            \"transforms\": \"ExtractMessageBody,ExtractMessageId\",
            \"transforms.ExtractMessageBody.type\": \"org.apache.kafka.connect.transforms.ExtractField\$Value\",
            \"transforms.ExtractMessageBody.field\": \"messageBody\",
            \"transforms.ExtractMessageId.type\": \"org.apache.kafka.connect.transforms.ExtractField\$Key\",
            \"transforms.ExtractMessageId.field\": \"MessageId\",
            \"key.converter\": \"org.apache.kafka.connect.storage.StringConverter\",
            \"value.converter\": \"org.apache.kafka.connect.converters.ByteArrayConverter\",
            \"azure.servicebus.connection.string\": \"$1\",
            \"azure.servicebus.max.message.count\": \"10\",
            \"azure.servicebus.max.waiting.time.seconds\": \"30\",
            \"confluent.license\": \"\",
            \"confluent.topic.bootstrap.servers\": \"broker:29092\",
            \"confluent.topic.replication.factor\": \"1\"
      }" \
      http://localhost:8083/connectors/az-sb-src-connector/config | jq .