# init-function.ps1
func init EventGridFunctionProj --worker-runtime dotnet --target-framework net8.0

$originalDir = Get-Location
try {
    Set-Location "$PSScriptRoot\EventGridFunctionProj"
   func new --name EventPublisherFunction --template "HTTP trigger"
}
catch {
    Write-Error "Script failed: $_"
}
finally {
    Set-Location $originalDir
}