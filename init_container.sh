#!/usr/bin/env bash
set -m # Enable job control

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

echo "***Setup openrc ..." && openrc && touch /run/openrc/softlevel

echo ***Starting ssh service...
rc-service sshd start

# Change to the home directory (helps keep paths relative to /home in used provided startup script)
cd /home
echo ***pwd: `pwd`

# If a custom initialization script is defined, run it and exit.
if [ -n "$INIT_SCRIPT" ]
then
    echo ***Running custom initialization script
    source $INIT_SCRIPT
    echo ***Finished running custom initialization script. Exiting.
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
    JBOSS_CLI
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
    echo ***Exporting env var $export_var
    # We use single quotes to preserve escape characters
	echo export $export_var=\'`printenv $export_var`\' >> ~/.profile
done

# Copy wardeployed apps to local location and create marker file for each
for dirpath in /home/site/wwwroot/webapps/*
do
    dir="$(basename -- $dirpath)"

    echo ***Copying $dirpath to $JBOSS_HOME/standalone/deployments/$dir.war
    cp -r $dirpath $JBOSS_HOME/standalone/deployments/$dir.war

    markerfile=$JBOSS_HOME/standalone/deployments/$dir.war.dodeploy

    echo ***Creating marker file $markerfile
    echo $dir > $markerfile
done

# Start Wildfly management server in the background. This helps us to proceed with the next steps like waiting for the server to be ready to run the startup script, etc
echo ***Starting Wildfly in the background...
$JBOSS_HOME/bin/standalone.sh -b 0.0.0.0 --admin-only &

function wait_for_server() {
  until `$JBOSS_HOME/bin/jboss-cli.sh -c ":read-attribute(name=server-state)" 2> /dev/null | grep -q running`; do
    sleep 1
    echo ***Server not ready, sleeping again
  done
}

echo ***Waiting for admin server to be ready
wait_for_server
echo ***Admin server is ready

# Get the startup file path
if [ -n "$1" ]
then
    # Path defined in the portal will be available as an argument to this script
    STARTUP_FILE=$1
else
    # Default startup file path
    STARTUP_FILE=/home/startup.sh
fi

# Run the startup file, if it exists
if [ -f $STARTUP_FILE ]
then
    echo ***Running startup file $STARTUP_FILE
    source $STARTUP_FILE
    echo ***Finished running startup file $STARTUP_FILE
else
    echo ***Looked for startup file $STARTUP_FILE, but did not find it, so skipping running it.
fi

echo ***Starting JBOSS application server
$JBOSS_HOME/bin/jboss-cli.sh -c "reload --server-config=standalone-full.xml"

# Now that we are done with all the steps, bring Wildfly to the foreground again before exiting. If we don't do this, the container will exit after the script exits which we don't want
echo ***Container initialization complete, now we bring Wildfly to foreground...
fg

echo ***Exiting init_container.sh (Ideally we should never reach this line)
