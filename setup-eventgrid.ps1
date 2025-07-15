# setup-eventgrid.ps1
. .\source.ps1  # Dot-source the variables file

az group create --name $RG_NAME --location $LOCATION

az storage account create --name $STORAGE_NAME --resource-group $RG_NAME --location $LOCATION --sku Standard_LRS

az storage queue create --name $QUEUE_NAME --account-name $STORAGE_NAME