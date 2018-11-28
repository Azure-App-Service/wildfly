# wildfly
This repository contains Docker images for Wildfly on Azure App Service.

## Build

```powershell
.\scripts\setup.ps1

# Note: $env:wildflyVersion referenced in the following command is set by setup.ps1
docker build --build-arg WILDFLY_VERSION=$env:wildflyVersion -t wildfly .
```

## Deploy and run the sample app to Azure
Run the following commands in powershell:
```powershell
cd .\samples\petstore

# usePostgresql = $true to use Postgresql. $false to use in-memory db.
..\..\scripts\deployAndRunApp.ps1 -imageName <imagename> [-webAppName <appname>] [-usePostgresql <$true | $false>]

# Example: ..\..\scripts\deployAndRunApp.ps1 -imageName myrepo/myimage:mytag
```
