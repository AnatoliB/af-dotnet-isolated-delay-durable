using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.Functions.Worker.Http;
using Microsoft.DurableTask;
using Microsoft.DurableTask.Client;
using Microsoft.Extensions.Logging;

namespace Company.Function;

public static class MyOrchestration
{
    [Function(nameof(MyOrchestration))]
    public static async Task<string> RunOrchestrator(
        [OrchestrationTrigger] TaskOrchestrationContext context)
    {
        ILogger logger = context.CreateReplaySafeLogger(nameof(MyOrchestration));
        
        // Get the delay duration from the orchestration input
        int delaySeconds = context.GetInput<int>();
        logger.LogInformation("Starting delay orchestration for {delaySeconds} seconds.", delaySeconds);

        // Call the Delay activity once
        string result = await context.CallActivityAsync<string>(nameof(Delay), delaySeconds);

        return result;
    }

    [Function(nameof(Delay))]
    public static async Task<string> Delay([ActivityTrigger] int delaySeconds, FunctionContext executionContext)
    {
        ILogger logger = executionContext.GetLogger("Delay");
        logger.LogInformation("Starting delay for {delaySeconds} seconds.", delaySeconds);
        
        await Task.Delay(TimeSpan.FromSeconds(delaySeconds));
        
        logger.LogInformation("Delay of {delaySeconds} seconds completed.", delaySeconds);
        return $"Delay of {delaySeconds} seconds completed successfully.";
    }

    [Function("MyOrchestration_HttpStart")]
    public static async Task<HttpResponseData> HttpStart(
        [HttpTrigger(AuthorizationLevel.Anonymous, "get", "post")] HttpRequestData req,
        [DurableClient] DurableTaskClient client,
        FunctionContext executionContext)
    {
        ILogger logger = executionContext.GetLogger("MyOrchestration_HttpStart");

        // Get delay duration from query parameter
        string delayParam = req.Query["delay"] ?? "5"; // Default to 5 seconds if not provided
        
        if (!int.TryParse(delayParam, out int delaySeconds) || delaySeconds <= 0)
        {
            logger.LogWarning("Invalid delay parameter: {delayParam}. Using default value of 5 seconds.", delayParam);
            delaySeconds = 5;
        }

        logger.LogInformation("Starting orchestration with delay of {delaySeconds} seconds.", delaySeconds);

        // Start orchestration with delay duration as input
        string instanceId = await client.ScheduleNewOrchestrationInstanceAsync(
            nameof(MyOrchestration), delaySeconds);

        logger.LogInformation("Started orchestration with ID = '{instanceId}'.", instanceId);

        // Returns an HTTP 202 response with an instance management payload.
        // See https://learn.microsoft.com/azure/azure-functions/durable/durable-functions-http-api#start-orchestration
        return await client.CreateCheckStatusResponseAsync(req, instanceId);
    }
}