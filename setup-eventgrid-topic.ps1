# setup-eventgrid-topic.ps1
. .\source.ps1

az eventgrid topic create --name $TOPIC_NAME --resource-group $RG_NAME --location $LOCATION

az eventgrid event-subscription create `
  --resource-group $RG_NAME `
  --topic-name $TOPIC_NAME `
  --name "demoSubscription" `
  --endpoint-type storagequeue `
  --endpoint "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RG_NAME/providers/Microsoft.Storage/storageAccounts/$STORAGE_NAME/queueServices/default/queues/$QUEUE_NAME"