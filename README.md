# Azure Event Grid Minimal Lab PowerShell (Enterprise Best Practices)

This repository demonstrates how to set up and exercise Azure Event Grid using practices consistent with enterprise best practices. All infrastructure provisioning and configuration steps use **PowerShell** (instead of Bash) for repeatability and automation. Application code is kept minimal, but structured as if for production. This guide can be followed to repeat the setup or adapt it for your own organization.

---

## Product Description

This project delivers a minimal enterprise-grade event-driven system using Azure services:

- **Azure Function (.NET):** An HTTP-triggered function that receives POST requests.
- **Event Grid:** Used by the Function to publish events/messages.
- **Azure Storage Queue:** Subscribes to the Event Grid topic and receives the events, acting as a durable backend for further processing.

**Operational Flow:**
1. External systems or users POST content to the Azure Function endpoint.
2. The Azure Function publishes an event to Event Grid.
3. Event Grid delivers the event to the configured Azure Storage Queue.
4. Downstream systems/processes can consume messages from the queue.

This pattern is highly adaptable for real-world enterprise workloads, ensuring scalability, durability, and maintainability.

---

## Testing Method

Follow this sequence to validate the system:

1. **Provision the Azure Storage Queue**
    - Create a storage account and queue using Azure CLI.

2. **Deploy the Azure Function**
    - Build and publish the .NET Azure Function to Azure.

3. **POST to the Function Endpoint**
    - Use PowerShell Invoke-RestMethod, `curl`, Postman, or similar tools to send data to the Function’s HTTP endpoint.

4. **Verify Message Delivery**
    - Check the Azure Storage Queue using Azure CLI, Azure Storage Explorer, or code to confirm the message exists.

---

## Table of Contents

- [Product Description](#product-description)
- [Testing Method](#testing-method)
- [Project Overview](#project-overview)
- [Technology Stack](#technology-stack)
- [Pre-requisites](#pre-requisites)
- [Azure CLI Setup](#azure-cli-setup)
- [Resource Provisioning](#resource-provisioning)
- [Application Setup](#application-setup)
- [Event Grid Exercise](#event-grid-exercise)
- [Enterprise Practices](#enterprise-practices)
- [Local Development (IDE)](#local-development-ide)
- [Cleanup](#cleanup)
- [References](#references)

---

## Project Overview

This project provisions Azure resources and exercises Event Grid with a minimal, repeatable workflow. It is suitable as a template for enterprise event-driven architectures and can be expanded for real-world products.

---

## Technology Stack

- **Infrastructure as Code:** Azure CLI scripts (now demonstrated using PowerShell; can be migrated to Bicep/Terraform)
- **Application:** .NET 8 (C#) for publisher/subscriber (replaceable with Java/Python/Node)
- **Event Grid Topic:** Custom topic
- **Authentication:** Azure AD (Service Principal recommended for automation)
- **Local Development:** Visual Studio Code (cross-platform), with recommended extensions

---

## Pre-requisites

- Azure subscription (with permissions to create resources)
- Azure CLI installed ([Install guide](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli))
- .NET 8 SDK ([Download](https://dotnet.microsoft.com/en-us/download/dotnet/8.0))
- Visual Studio Code ([Download](https://code.visualstudio.com/)) or preferred IDE
- jq (for scripting convenience, optional)

---

## Azure CLI Setup

1. **Login**
   ```powershell
   az login
   ```

2. **Set Default Subscription**
   ```powershell
   az account set --subscription "<your-subscription-id>"
   ```

3. **(Optional) Create Service Principal**
   For CI/CD or automation:
   ```powershell
   az ad sp create-for-rbac --name "<your-app-name>" --role contributor
   ```

---

## Resource Provisioning (Best Practice: Modular Scripts and Sourcing Variables)

Use modular **`.ps1`** files for each step, loading a common `source.ps1` file for variables. This approach ensures consistency, repeatability, and easy maintenance.

### 1. Create a `source.ps1` file for shared variables - modify variable contents as needed

```powershell name=source.ps1
# source.ps1

$RG_NAME      = "az-204-eventgrid-lab-rg"
$LOCATION     = "westus"
$STORAGE_NAME = "eventgridlabstorage2025071408"
$QUEUE_NAME   = "eventgridqueue"
$TOPIC_NAME   = "topic-eventgrid-demo"

# Try to get subscription ID from environment variable, otherwise fetch from Azure CLI
if ($env:AZURE_SUBSCRIPTION_ID) {
    $SUBSCRIPTION_ID = $env:AZURE_SUBSCRIPTION_ID
} else {
    $SUBSCRIPTION_ID = (az account show --query id -o tsv)
}

Write-Host "Resource Group: $RG_NAME"
Write-Host "Location: $LOCATION"
Write-Host "Storage Account: $STORAGE_NAME"
Write-Host "Queue Name: $QUEUE_NAME"
Write-Host "Topic Name: $TOPIC_NAME"
Write-Host "Subscription ID: $SUBSCRIPTION_ID"
```

### 2. Create a script to provision resources (`setup-eventgrid.ps1`) and run it.

```powershell name=setup-eventgrid.ps1
# setup-eventgrid.ps1
. .\source.ps1  # Dot-source the variables file

az group create --name $RG_NAME --location $LOCATION

az storage account create --name $STORAGE_NAME --resource-group $RG_NAME --location $LOCATION --sku Standard_LRS

az storage queue create --name $QUEUE_NAME --account-name $STORAGE_NAME
```

### 3. Application Setup

#### Create script to Scaffold a new Azure Function (.NET) with HTTP Trigger (`init-function.ps1`) and run it.

```powershell name=init-function.ps1
# init-function.ps1
func init EventGridFunctionProj --worker-runtime dotnet --target-framework net8.0
Set-Location EventGridFunctionProj
func new --name EventPublisherFunction --template "HTTP trigger"
```

#### Create script to Add packages for Event Grid publishing (`add-packages.ps1`) and run it.

```powershell name=add-packages.ps1
# add-packages.ps1
dotnet add package Azure.Messaging.EventGrid
dotnet add package Azure.Storage.Queues
```

#### Implement Function logic (.NET) to POST incoming payloads to Azure Storage Queue

Create `EventPublisherFunction.cs` in your Azure Function project:

```csharp
using System.IO;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Extensions.Http;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Logging;
using Azure.Storage.Queues;

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
```

Set up `local.settings.json` with your storage connection string and queue name:

```json
{
  "IsEncrypted": false,
  "Values": {
    "AzureWebJobsStorage": "<your_storage_connection_string>",
    "QueueName": "eventgridqueue"
  }
}
```

---

This function receives POST requests, reads the payload, and enqueues it to the Azure Storage Queue. Configure your resource provisioning and Event Grid subscription as described above to complete the workflow.

---

### 4. Configure Event Grid Topic & Subscription (before deploying Function)

#### Create Event Grid topic and subscribe Storage Queue

```powershell name=setup-eventgrid-topic.ps1
# setup-eventgrid-topic.ps1
. .\source.ps1

az eventgrid topic create --name $TOPIC_NAME --resource-group $RG_NAME --location $LOCATION

az eventgrid event-subscription create `
  --resource-group $RG_NAME `
  --topic-name $TOPIC_NAME `
  --name "demoSubscription" `
  --endpoint-type storagequeue `
  --endpoint "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RG_NAME/providers/Microsoft.Storage/storageAccounts/$STORAGE_NAME/queueServices/default/queues/$QUEUE_NAME"
```

---

### 5. Deploy Function to Azure

```powershell name=deploy-function.ps1
# deploy-function.ps1
. .\source.ps1

Set-Location EventGridFunctionProj

az functionapp create --resource-group $RG_NAME --consumption-plan-location $LOCATION --runtime dotnet --functions-version 4 --name "EventGridFunctionProj" --storage-account $STORAGE_NAME

func azure functionapp publish EventGridFunctionProj
```

---

### 6. Event Grid Exercise (Test Locally and in Cloud)

**Note:** These tests can be performed twice:
- First, after the subscription step above, using the local endpoint.
- Again, after the deployment step above, using the cloud endpoint.

#### Send a POST Request to the Azure Function

```powershell
# Example using PowerShell's Invoke-RestMethod
Invoke-RestMethod -Uri "<function-endpoint-url>" -Method POST -ContentType "application/json" -Body '{"data":"sample"}'
```

#### Function publishes event to Event Grid.

#### Event Grid delivers event to the Storage Queue.

#### Check the Storage Queue

```powershell
az storage message peek --queue-name $QUEUE_NAME --account-name $STORAGE_NAME
```

---

**Summary:**  
- Use modular **`.ps1`** scripts for each step.
- Use a common `source.ps1` for variables.
- Always dot-source (`. .\source.ps1`) in each script for consistent variable access.
- This pattern applies for both multi-line and one-liner scripts if variables or config are needed.

---

## Enterprise Practices

- **Automation:** All steps scripted with Azure CLI; can be converted to CI/CD or IaC templates.
- **Security:** Use Azure AD Service Principal for automation and RBAC for resource control.
- **Naming Conventions:** Use consistent, discoverable resource names.
- **Separation of Concerns:** Separate publisher, topic, and subscriber logic.
- **Monitoring:** Enable diagnostics on Event Grid topic and endpoints.

---

## Local Development (IDE)

1. **Open Solution in VS Code**
   ```powershell
   code .
   ```

2. **Recommended Extensions**
   - C# (OmniSharp)
   - Azure Tools
   - Azure CLI Tools

3. **Debug/Run**
   - Use built-in VS Code terminal for CLI commands.
   - Use VS Code debugger for .NET app.

---

## Cleanup

To remove all resources:
```powershell
az group delete --name $RG_NAME --yes
```

---

## References

- [Azure Event Grid Documentation](https://docs.microsoft.com/en-us/azure/event-grid/)
- [Azure CLI Reference](https://docs.microsoft.com/en-us/cli/azure/eventgrid)
- [Enterprise Patterns for Event Grid](https://learn.microsoft.com/en-us/azure/architecture/guide/architecture-styles/event-driven)
- [.NET Event Grid SDK](https://learn.microsoft.com/en-us/dotnet/api/overview/azure/eventgrid)

---

## Next Steps

- Expand publisher/subscriber code for real scenarios
- Integrate with CI/CD pipeline
- Implement more secure authentication flows

```
