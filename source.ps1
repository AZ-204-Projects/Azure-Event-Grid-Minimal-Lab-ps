# source.ps1

$RG_NAME      = "az-204-eventgrid-lab-rg"
$LOCATION     = "westus"
$STORAGE_NAME = "eventgridstorage0714am"
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