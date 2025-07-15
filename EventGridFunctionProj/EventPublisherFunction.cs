using Azure.Storage.Queues;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Extensions.Http;
using Microsoft.Extensions.Logging;
using System;
using System.IO;
using System.Threading.Tasks;

public static class EventPublisherFunction
{
    [FunctionName("EventPublisherFunction")]
    public static async Task<IActionResult> Run(
        [HttpTrigger(AuthorizationLevel.Function, "post", Route = null)] HttpRequest req,
        ILogger log)
    {
        // optional logging
        log.LogInformation("C# HTTP trigger function processing a request.");

        string requestBody = await new StreamReader(req.Body).ReadToEndAsync();

        // Get connection string and queue name from environment variables
        string queueConnectionString = Environment.GetEnvironmentVariable("AzureWebJobsStorage");
        string queueName = Environment.GetEnvironmentVariable("QueueName"); // set this in local.settings.json

        // optional logging
        log.LogInformation($"queueName:{queueName}.");

        var queueClient = new QueueClient(queueConnectionString, queueName);
        await queueClient.CreateIfNotExistsAsync();

        // Enqueue message
        await queueClient.SendMessageAsync(requestBody);

        return new OkObjectResult($"Message sent to queue: {queueName}");
    }
}