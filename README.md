# Introduction

The repo shows how to configure a Azure Service Bus Source Connector to write the original payload as a struct and the key as a string onto Kafka.
The problem is that even that it is based on AMQP and has a native JSON format that is the entire message envelope and the message you produce to is stored as string encoded bytes in the 'messageBody' field.

When creating the connector, intuition might suggest that you use the `org.apache.kafka.connect.json.JsonConverter` for the key and value transformations. The problem there is two fold, what it generates is another envelop with the JSON Schema and the payload which contains the service bus envelope which contains the messageBody which is a string encoded byte array. So this converter makes things worse.

I this example we are producing a JSON message and we are interested in getting that JSON into a Kafka topic using the Azure Service Bus connector and the key lies in the connector configuration, skip to conclusion for the TL;DR;.

## Prerequisites

* Docker and Docker Compose
* .Net 6.0 SDK or higher
* Ability to create a Azure Service Bus instance on Azure account - Can be done using trial credits

## Getting Started

This demo works best using 3 terminals. And follwing the steps below or something similar:

* Create a Azure Service Bus instance on Azure and add a queue to it. Note the namespace and queue name.
* This demo works with SAS tokens, you can find them under 'Shared access policies' under the Service Bus level. You can create your own, say 'PubSubUser', and grant 'listen' and 'send' permissions, but the 'RootManageSharedAccessKey' can be used.
* Note down the connection string by clicking the desired user policy and note the connection string. Format: `Endpoint=sb://<namespace>.servicebus.windows.net/;SharedAccessKeyName=<policy>;SharedAccessKey=<secret>`.
* Create a queue and add it to your connection string: New format: `Endpoint=sb://<namespace>.servicebus.windows.net/;SharedAccessKeyName=<policy>;SharedAccessKey=<secret>;EntityPath=<queue>`.
* Terminal 1: Produce a message onto service bus by navigating to the `/src` directory and type `dotnet run "<connection_string>"`. The double quotes are likely necessary. It will print the JSON data produced to Azure Service Bus.
* Terminal 2: Start the environment by running `docker-compose up -d`.
* Terminal 2: Install the Azure Service Bus Source connector by running `connector-install.sh`
* You can now preview the message in the queue on Azure by using the 'Peek next messages' in the 'Service Bus Explorer' by navigating to the queue in the portal. The payload should match the produced data, also note the 'Message ID'.
* Terminal 2: Wait a few seconds for the connect container to be available, then deploy the connector by running `connector-deploy.sh "<connection_string>"`. Again, double quotes are likely necessary.
* Terminal 3: Start a consumer by running `consumer-run.sh`.

You should now see the key corresponding to the 'Message ID' and the value corresponding to the produced JSON.

To clean up:
* Terminal 3: 'CTRL-C' out of the consumer
* Terminal 2: Hit 'Enter' to exit the program.
* Terminal 1: Run `docker-compose down -v`.

## Conclusion

If you inspect the `deploy-connector.sh` you will find the secret sauce is a combination of transform and the value converters.

Since the values are read from Service Bus as struct (not string) we can apply transformations directly one for key one for value:
```
"transforms": "ExtractMessageBody,ExtractMessageId",
"transforms.ExtractMessageBody.type": "org.apache.kafka.connect.transforms.ExtractField$Value",
"transforms.ExtractMessageBody.field": "messageBody",
"transforms.ExtractMessageId.type": "org.apache.kafka.connect.transforms.ExtractField$Key",
"transforms.ExtractMessageId.field": "MessageId",
```
This 'extract' transform operates directly on the service bus envelope and extracts the value from 'messageBody' which now is just bytes. Same with the 'MessageId' field from the key which is now just a string.
With those values in hand, we new tell Kafka the types of these values and mind you that the key is just a string so we use `"key.converter": "org.apache.kafka.connect.storage.StringConverter"` and for the payload wich is already JSON but just as bytes we just write the bytes as-is: `"value.converter": "org.apache.kafka.connect.converters.ByteArrayConverter"`.

Voulà!