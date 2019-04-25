function setup
{
	param([string]$version)

    $tmpDirRootPath = $version + '/tmp'

    # Copy the shared files to the target directory
    copy-item -Force -recurse shared "$tmpDirRootpath"
    
    $dockerFileTemplatePath = '.\shared\misc\Dockerfile'
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

    $wildflyLocalPath = "$tmpDirRootPath\wildfly-$wildflyVersion.tar.gz"
    If(!(test-path $wildflyLocalPath))
    {
        Invoke-WebRequest -Uri https://download.jboss.org/wildfly/$wildflyVersion/wildfly-$wildflyVersion.tar.gz -OutFile $wildflyLocalPath
    }

    $headerFooter = "########################################################`n### ***DO NOT EDIT*** This is an auto-generated file ###`n########################################################`n"
    $content = $headerFooter + $content + $headerFooter
    Set-Content -Value $content -Path $dockerFileOutPath
}

setup -version '14-jre8'
