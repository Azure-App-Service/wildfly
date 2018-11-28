# wildfly
This repository contains Docker images for Wildfly on Azure App Service.

## Build

```powershell
.\scripts\setup.ps1

# Note: $env:wildflyVersion referenced in the following command is set by setup.ps1
docker build --build-arg WILDFLY_VERSION=$env:wildflyVersion -t wildfly .
```