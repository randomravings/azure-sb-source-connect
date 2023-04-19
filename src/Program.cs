using Azure.Messaging.ServiceBus;
using Newtonsoft.Json;

Console.WriteLine(args[0]);
var props = ServiceBusConnectionStringProperties.Parse(args[0]);

var clientOptions = new ServiceBusClientOptions
{
    TransportType = ServiceBusTransportType.AmqpWebSockets
};
await using var client = new ServiceBusClient(
    args[0],
    clientOptions
);
await using var sender = client.CreateSender(props.EntityPath);
try
{
    Console.WriteLine("Type in a name and press 'return' to produce and event to Azure Service Bus.");
    Console.WriteLine("Hitting 'return' without any input will exit the program.");
    var id = 10000;
    do
    {
        Console.Write("> input: ");
        var name = Console.ReadLine();
        if (string.IsNullOrEmpty(name))
            break;

        var eventData = new EventData(
            id++,
            name
        );

        var eventEnvelope = new EventEnvelope(
            Guid.NewGuid(),
            DateTimeOffset.Now,
            "UpdateName",
            eventData
        );

        var body = JsonConvert.SerializeObject(eventEnvelope, Formatting.Indented);
        Console.WriteLine($"> output: {body}");
        var message = new ServiceBusMessage(body);
        await sender.SendMessageAsync(message);
    }
    while (true);
}
catch (Exception ex)
{
    Console.WriteLine(ex.ToString());
}
finally
{
    await sender.DisposeAsync();
    await client.DisposeAsync();
}

sealed record EventEnvelope(
    Guid Id,
    DateTimeOffset Timestamp,
    string Action,
    EventData Data
);

sealed record EventData(
    int Id,
    string Name
);