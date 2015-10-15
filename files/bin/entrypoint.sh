#!/usr/bin/env bash

CARBON_HOME=${CARBON_HOME:-/opt/wso2}

getEnvironmentVarsAsProperties () {
    # Take any environment variables prefixed with APP_, remove the APP_ prefix, then change underscores to periods
    for name in `printenv | grep -E -o '^APP_[A-Za-z0-9_]+'`; do
        if [ "$name" != "" ]; then
            prop=`echo $name | awk '{gsub(/^APP_/, "");gsub("_", "."); print $0}'`
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

# Overlay everything from /extra into /opt/wso2
if [ -d /extra ] && [ "`ls -A /extra`" ]; then
    cp -R /extra/* ${CARBON_HOME}/
fi

# Create tmp file
tmp=`mktemp -t "entrypoint.XXXXXXXXXX"`

# Read in the default.properties file
appendPropertiesFile "${CARBON_HOME}/default.properties" "$tmp"

# Read in the app.properties file
appendPropertiesFile "${CARBON_HOME}/app.properties" "$tmp"

# Read in the environment variables last (they take priority)
getEnvironmentVarsAsProperties >> $tmp

# Run the $tmp file through the property-parser to produce java property arguments
#OPTS=`java -jar ${CARBON_HOME}/bin/property-parser.jar $tmp -d`

cd "${CARBON_HOME}/templates"
find -type f | while read fname; do
  template "$fname" "$tmp"
done

# Remove the tmp file
rm $tmp

PUBLIC_IP=`head -n 1 /etc/hosts | awk '{print $1}'`

xmlstarlet edit --inplace -u "/axisconfig/clustering/@enable" -v "${CLUSTERING_ENABLED:-false}" ${CARBON_HOME}/repository/conf/axis2/axis2.xml
xmlstarlet edit --inplace -u "/axisconfig/clustering/parameter[@name='domain']/@name" -v "${CLUSTER_DOMAIN:-wso2.carbon.domain}" ${CARBON_HOME}/repository/conf/axis2/axis2.xml
xmlstarlet edit --inplace -u "/axisconfig/clustering/parameter[@name='membershipScheme']" -v "${CLUSTERING_MEMBERSHIP_SCHEME:-multicast}" ${CARBON_HOME}/repository/conf/axis2/axis2.xml
xmlstarlet edit --inplace -u "/axisconfig/clustering/parameter[@name='localMemberHost']" -v "${MULTICAST_PUBLISH_IP:-$PUBLIC_IP}" ${CARBON_HOME}/repository/conf/axis2/axis2.xml

# Insert the <parameter name="HostnameVerifier">AllowAll</parameter> element ...
# this is to allow the HTTPS requests passed through from the api-server to internal servers to allow any hostname
xmlstarlet edit --inplace -s "/axisconfig/transportSender[@name='https']" -t elem -n parameter -v "${HTTPS_HOSTNAME_VERIFIER:-DefaultAndLocalhost}" \
           -i "/axisconfig/transportSender[@name='https']/parameter[not(@name)]" -t attr -n name -v HostnameVerifier \
           ${CARBON_HOME}/repository/conf/axis2/axis2.xml


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
