#!/usr/bin/env bash
cat >/etc/motd <<EOL
  _____                               
  /  _  \ __________ _________   ____  
 /  /_\  \\___   /  |  \_  __ \_/ __ \ 
/    |    \/    /|  |  /|  | \/\  ___/ 
\____|__  /_____ \____/ |__|    \___  >
        \/      \/                  \/ 
A P P   S E R V I C E   O N   L I N U X

Documentation: http://aka.ms/webapp-linux
EOL
cat /etc/motd

echo "Setup openrc ..." && openrc && touch /run/openrc/softlevel

echo Starting ssh service...
rc-service sshd start

# If a custom initialization script is defined, run it and exit.
if [ -n "$INIT_SCRIPT" ]
then
    echo Running custom initialization script
    source $INIT_SCRIPT
    echo Finished running custom initialization script. Exiting.
    exit
fi

if [ ! -d /home/site/wwwroot/webapps ]
then
    mkdir -p /home/site/wwwroot
    cp -r /tmp/wildfly/webapps /home/site/wwwroot
fi

# WEBSITE_INSTANCE_ID will be defined uniquely for each worker instance while running in Azure.
# During development it may not be defined, in that case  we set WEBSITE_INSTNACE_ID=dev.
if [ -z "$WEBSITE_INSTANCE_ID" ]
then
    export WEBSITE_INSTANCE_ID=dev
fi

# For now keep it simple by copying everything
cp -r /home/site/wwwroot/webapps/* $JBOSS_HOME/standalone/deployments/

# Move ROOT to ROOT.war (temporarily, till the Maven plugin starts supporting deployment to dirs with .war extension)
if [ -d $JBOSS_HOME/standalone/deployments/ROOT ]
then
    if [ ! -d $JBOSS_HOME/standalone/deployments/ROOT.war ]
    then
        mv $JBOSS_HOME/standalone/deployments/ROOT $JBOSS_HOME/standalone/deployments/ROOT.war
    fi
fi

# Create marker file
for dir in $JBOSS_HOME/standalone/deployments/*.war
do
    echo Creating $dir.dodeploy
    echo $dir > $dir.dodeploy
done

# After all env vars are defined, add the ones of interest to ~/.profile
# Adding to ~/.profile makes the env vars available to new login sessions (ssh) of the same user.

# list of variables that will be added to ~/.profile
export_vars=()

# Step 1. Add app settings to ~/.profile
# To check if an environment variable xyz is an app setting, we check if APPSETTING_xyz is defined as an env var
while read -r var
do
    if [ -n "`printenv APPSETTING_$var`" ]
    then
        export_vars+=($var)
    fi
done <<< `printenv | cut -d "=" -f 1 | grep -v ^APPSETTING_`

# Step 2. Add well known environment variables to ~/.profile
well_known_env_vars=( 
    JBOSS_HOME
    WILDFLY_VERSION
    HTTP_LOGGING_ENABLED
    WEBSITE_SITE_NAME
    WEBSITE_ROLE_INSTANCE_ID
    TOMCAT_VERSION
    JAVA_OPTS
    JAVA_HOME
    JAVA_VERSION
    WEBSITE_INSTANCE_ID
    _JAVA_OPTIONS
    JAVA_ALPINE_VERSION
    JAVA_DEBIAN_VERSION
    )

for var in "${well_known_env_vars[@]}"
do
    if [ -n "`printenv $var`" ]
    then
        export_vars+=($var)
    fi
done

# Step 3. Add environment variables with well known prefixes to ~/.profile
while read -r var
do
    export_vars+=($var)
done <<< `printenv | cut -d "=" -f 1 | grep -E "^(WEBSITE|APPSETTING|SQLCONNSTR|MYSQLCONNSTR|SQLAZURECONNSTR|CUSTOMCONNSTR)_"`

# Write the variables to be exported to ~/.profile
for export_var in "${export_vars[@]}"
do
    echo Exporting env var $export_var
    # We use single quotes to preserve escape characters
	echo export $export_var=\'`printenv $export_var`\' >> ~/.profile
done

# Start Tomcat
echo Starting Wildfly...

$JBOSS_HOME/bin/standalone.sh -c standalone-full.xml
