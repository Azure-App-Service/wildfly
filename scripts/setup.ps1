[CmdletBinding()]
Param(
    [Parameter(Mandatory=$False, HelpMessage='Example: $true for using previously downloaded WildFly to speed up setup time')]
    [bool]$incremental=$false
)

function setup
{
    param([string]$version)

    $tmpDirRootPath = $version + '/tmp'

    If (Test-Path $tmpDirRootPath)
    {
        remove-item -recurse -force $tmpDirRootPath
    }

    # Copy the shared files to the target directory
    copy-item -recurse shared "$tmpDirRootpath\shared"
    
    $dockerFileTemplatePath = '.\shared\appservice\Dockerfile'
    $dockerFileOutPath = "$version\Dockerfile"

    # Generate the Dockerfile from the template and place it in the target directory
    # Also, copy Tomcat version specific files to the target directory
    switch ($version)
    {
        '14-jre8'
        {
            $wildflyMajorVersion = '14'
            $wildflyVersion = '14.0.1.Final'

            $content = ((Get-Content -path $dockerFileTemplatePath -Raw) `
                -replace '__PLACEHOLDER_BASEIMAGE__', 'mcr.microsoft.com/java/jre-headless:8u212-zulu-alpine-with-tools') `
                -replace '__PLACEHOLDER_WILDFLY_MAJOR_VERSION__', $wildflyMajorVersion `
                -replace '__PLACEHOLDER_WILDFLY_VERSION__', $wildflyVersion
            
            break
        }
    }

    # Convert relative path to absolute path (for logging purposes)
    $wildflyLocalPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath("$tmpDirRootPath\wildfly-$wildflyVersion.tar.gz")

    # If $incremental == $true and a local copy of WildFly exists, use it
    If($incremental -and (test-path "$env:TEMP\wildfly-$wildflyVersion.tar.gz"))
    {
        Write-Host "SKIPPING download"
        Write-Host "Using previously downloaded copy of WildFly from $env:TEMP\wildfly-$wildflyVersion.tar.gz"
        copy-item "$env:TEMP\wildfly-$wildflyVersion.tar.gz" $wildflyLocalPath
    }

    If(!(test-path $wildflyLocalPath))
    {
        $wildflyUrl = "https://download.jboss.org/wildfly/$wildflyVersion/wildfly-$wildflyVersion.tar.gz"
        Write-Host "Downloading $wildflyUrl to $wildflyLocalPath ..."
        (New-Object System.Net.WebClient).DownloadFile($wildflyUrl, $wildflyLocalPath)
        copy-item $wildflyLocalPath "$env:TEMP\wildfly-$wildflyVersion.tar.gz"
        Write-Host "Download complete - $wildflyLocalPath"
    }

    $headerFooter = "########################################################`n### ***DO NOT EDIT*** This is an auto-generated file ###`n########################################################`n"
    $content = $headerFooter + $content + $headerFooter
    Set-Content -Value $content -Path $dockerFileOutPath
}

setup -version '14-jre8'
