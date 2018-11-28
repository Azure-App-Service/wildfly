[CmdletBinding()]
Param(
	[Parameter(Mandatory=$True, HelpMessage='Example: perftest1. This will create a web app http://perftest1.azurewebsites.net')]
	[string]$webAppName,

	[Parameter(Mandatory=$True, HelpMessage='Example: myrepo/wildfly')]
	[string]$imageName,

	[Parameter(Mandatory=$False, HelpMessage='Example: $true for using postgresql instead of an in-memory db')]
	[bool]$usePostgresql=$false
)

$env:RESOURCEGROUP_NAME='tomcat-perftest2'
$env:WEBAPP_NAME=$webAppName
$env:WEBAPP_PLAN_NAME=$webAppName # use the same name for the web app and app service plan
$env:IMAGE_NAME=$imageName
$env:REGION='westus'

if ($usePostgresql -eq $true)
{
	Copy-Item -Force .\persistence-postgresdb.xml .\src\main\resources\META-INF\persistence.xml
}
else
{
	Copy-Item -Force .\persistence-inmemorydb.xml .\src\main\resources\META-INF\persistence.xml
}

Write-Host -ForegroundColor Green "Deploying to '$env:WEBAPP_NAME'"
Write-Host -ForegroundColor Green "Container Name: '$env:IMAGE_NAME'"
Write-Host -ForegroundColor Green "Resource group: '$env:RESOURCEGROUP_NAME'"
Write-Host -ForegroundColor Green "Using Postgresql: '$usePostgresql'"

mvn package -DskipTests
mvn azure-webapp:deploy
