$env:wildflyVersion='14.0.1.Final'

$path = ".\tmp"
If(!(test-path $path))
{
      New-Item -ItemType Directory -Force -Path $path
}

Invoke-WebRequest -Uri https://download.jboss.org/wildfly/$env:wildflyVersion/wildfly-$env:wildflyVersion.tar.gz -OutFile .\tmp\wildfly-$env:wildflyVersion.tar.gz
