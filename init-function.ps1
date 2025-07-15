# init-function.ps1
func init EventGridFunctionProj --worker-runtime dotnet --target-framework net8.0
Set-Location EventGridFunctionProj
func new --name EventPublisherFunction --template "HTTP trigger"