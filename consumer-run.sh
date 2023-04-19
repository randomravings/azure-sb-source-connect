#!/bin/bash
kafka-console-consumer \
    --bootstrap-server localhost:9092 \
    --topic input-topic \
    --property print.timestamp=true \
    --property print.key=true \
    --property key.separator=" | " \
    --from-beginning