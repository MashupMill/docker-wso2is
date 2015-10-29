#!/usr/bin/env bash

CARBON_HOME=${CARBON_HOME:-/opt/wso2}

getEnvironmentVarsAsProperties () {
    # Take any environment variables prefixed with APP_, remove the APP_ prefix, then change underscores to periods
    for name in `printenv | grep -E -o '^[A-Za-z0-9_]+'`; do
        if [ "$name" != "" ]; then
            prop=`echo $name | awk '{gsub("__", "."); print $0}'`
            echo "$prop=${!name}"
        fi
    done
}

appendPropertiesFile () {
    if [ -f "$1" ]; then
        echo "Appending properties file $1"
        cat "$1" >> "$2"
        echo '' >> "$2"
    else
        echo "$1 not found; will skip appending it"
    fi
}

template () {
    INPUT=$1
    PROPS=$2
    echo -n "Found file for templating $INPUT..."
    mkdir -p `dirname "$CARBON_HOME/$INPUT"`
    java -jar "${CARBON_HOME}/bin/property-parser.jar" template -o "$CARBON_HOME/$INPUT" "$PROPS" "$INPUT"
    echo "done"
}

get-prop () {
    echo "\${$1}" | java -jar "${CARBON_HOME}/bin/property-parser.jar" template "$2"
}

# Overlay everything from /extra into /opt/wso2
if [ -d /extra ] && [ "`ls -A /extra`" ]; then
    cp -R /extra/* ${CARBON_HOME}/
fi

export CONTAINER_IP=`head -n 1 /etc/hosts | awk '{print $1}'`

# Process the well known address envrionment variable
for member in $WELL_KNOWN_ADDRESSES; do
    host=`echo $member | awk -F':' '{print $1}'`
    port=`echo $member | awk -F':' '{print $2}'`
    export WELL_KNOWN_MEMBERS="$WELL_KNOWN_MEMBERS<member><hostName>${host}</hostName><port>${port:-4000}</port></member>"
done

# Create tmp file
PROPERTIES_FILE=`mktemp -t "entrypoint.XXXXXXXXXX"`

# Read in the default.properties file
appendPropertiesFile "${CARBON_HOME}/default.properties" "$PROPERTIES_FILE"

# Read in the app.properties file
appendPropertiesFile "${CARBON_HOME}/app.properties" "$PROPERTIES_FILE"

# Read in the environment variables last (they take priority)
getEnvironmentVarsAsProperties >> $PROPERTIES_FILE

if [[ "$MOUNT_REGISTRY" == "true" ]]; then
    echo 'wso2registry.mount.prefix=
wso2registry.mount.suffix=' >> $PROPERTIES_FILE
else
    echo 'wso2registry.mount.prefix=<!--
wso2registry.mount.suffix=-->' >> $PROPERTIES_FILE
fi

# Run the $PROPERTIES_FILE file through the property-parser to produce java property arguments
#OPTS=`java -jar ${CARBON_HOME}/bin/property-parser.jar $PROPERTIES_FILE -d`

# Go through each file in the templates directory and run it through the property-parser templating tool to replace
# instances of ${Property.Name} with the actual property value.
cd "${CARBON_HOME}/templates"
find -type f | while read fname; do
  template "$fname" "$PROPERTIES_FILE"
done

# If we have deployment synchronizer turned on and its pointing to a local svn repo (presumably it is a shared mount)
# and its an empty directory, we need to initialize the svn repo
DEPSYNC_ON=`get-prop Server.DeploymentSynchronizer.Enabled ${PROPERTIES_FILE}`
DEPSYNC_WRITE=`get-prop Server.DeploymentSynchronizer.AutoCommit ${PROPERTIES_FILE}`
DEPSYNC_URL=`get-prop Server.DeploymentSynchronizer.SvnUrl ${PROPERTIES_FILE}`
DEPSYNC_REPO=`echo "${DEPSYNC_URL:7}"`
DEPSYNC_USER=`get-prop Server.DeploymentSynchronizer.SvnUser ${PROPERTIES_FILE}`
DEPSYNC_PASS=`get-prop Server.DeploymentSynchronizer.SvnPassword ${PROPERTIES_FILE}`
DEPSYNC_PATH=${DEPSYNC_PATH:--1234}

if [[ "$DEPSYNC_ON" == "true" && "$DEPSYNC_WRITE" == "true" && "$DEPSYNC_URL" == file://* && -d "$DEPSYNC_REPO" && ! ("`ls -A $DEPSYNC_REPO`") ]]; then
    echo "initializing deployment syncronization repo at $DEPSYNC_REPO"
    svnadmin create "$DEPSYNC_REPO"
    sed -E -i 's/(# )?anon-access.*/anon-access = none/' "$DEPSYNC_REPO/conf/svnserve.conf"
    sed -E -i 's/(# )?auth-access.*/auth-access = write/' "$DEPSYNC_REPO/conf/svnserve.conf"
    sed -E -i 's/(# )?password-db.*/password-db = passwd/' "$DEPSYNC_REPO/conf/svnserve.conf"
    echo "$DEPSYNC_USER:$DEPSYNC_PASS" >> "$DEPSYNC_REPO/conf/passwd"
fi

if [[ "$DEPSYNC_ON" == "true" && "$DEPSYNC_PATH" != "" && "$DEPSYNC_PATH" != "false" ]]; then
    svn --help >> /dev/null
    sed -E -i 's/(# )?store-plaintext-passwords.*/store-plaintext-passwords = no/' ~/.subversion/servers
    if [[ "`svn ls --username "$DEPSYNC_USER" --password "$DEPSYNC_PASS" $DEPSYNC_URL/$DEPSYNC_PATH`" ]]; then
        echo "DepSync dir is not empty, we will check it out and move it in place"
        rm -fr "${CARBON_HOME}/repository/deployment/server"
        svn checkout --username "$DEPSYNC_USER" --password "$DEPSYNC_PASS" --quiet "$DEPSYNC_URL/$DEPSYNC_PATH" "${CARBON_HOME}/repository/deployment/server"
    fi
fi

# Remove the PROPERTIES_FILE file
rm $PROPERTIES_FILE

# Set the http proxy port if provided
xmlstarlet edit --inplace --delete "/Server/Service/Connector[not(@secure)]/@proxyPort" ${CARBON_HOME}/repository/conf/tomcat/catalina-server.xml
[ "${HTTP_PROXY_PORT}" != "" ] &&  xmlstarlet edit --inplace --insert "/Server/Service/Connector[not(@secure)]" --type attr -n proxyPort --value "${HTTP_PROXY_PORT}" ${CARBON_HOME}/repository/conf/tomcat/catalina-server.xml

# Set the https proxy port if provided
xmlstarlet edit --inplace --delete "/Server/Service/Connector[@secure='true']/@proxyPort" ${CARBON_HOME}/repository/conf/tomcat/catalina-server.xml
[ "${HTTPS_PROXY_PORT}" != "" ] &&  xmlstarlet edit --inplace --insert "/Server/Service/Connector[@secure='true']" --type attr -n proxyPort --value "${HTTPS_PROXY_PORT}" ${CARBON_HOME}/repository/conf/tomcat/catalina-server.xml

if [ "$PROFILE" != "" ]; then
    OPTS="-Dprofile=$PROFILE $OPTS"
fi

if [ -f "${CARBON_HOME}/bin/extra.sh" ]; then
    chmod a+x ${CARBON_HOME}/bin/extra.sh
    ${CARBON_HOME}/bin/extra.sh
fi

sleep ${DELAY_START:-0}

${CARBON_HOME}/bin/wso2server.sh "$@" "${OPTS}"
