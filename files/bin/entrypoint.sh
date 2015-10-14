#!/usr/bin/env bash

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

# Overlay everything from /extra into /opt/wso2
if [ -d /extra ] && [ "`ls -A /extra`" ]; then
    cp -R /extra/* /opt/wso2/
fi

# Create tmp file
tmp=`mktemp -t "entrypoint.XXXXXXXXXX"`

# Read in the environment variables first (they take priority)
getEnvironmentVarsAsProperties >> $tmp

# Read in the app.properties file
appendPropertiesFile '/opt/wso2/app.properties' "$tmp"

# Read in the default.properties file
appendPropertiesFile '/opt/wso2/default.properties' "$tmp"

# Run the $tmp file through the property-parser to produce java property arguments
OPTS=`java -jar /opt/wso2/bin/property-parser-1.3.jar $tmp -d`

# Remove the tmp file
rm $tmp

PUBLIC_IP=`head -n 1 /etc/hosts | awk '{print $1}'`

xmlstarlet edit --inplace -u "/axisconfig/clustering/@enable" -v "${CLUSTERING_ENABLED:-false}" /opt/wso2/repository/conf/axis2/axis2.xml
xmlstarlet edit --inplace -u "/axisconfig/clustering/parameter[@name='domain']/@name" -v "${CLUSTER_DOMAIN:-wso2.carbon.domain}" /opt/wso2/repository/conf/axis2/axis2.xml
xmlstarlet edit --inplace -u "/axisconfig/clustering/parameter[@name='membershipScheme']" -v "${CLUSTERING_MEMBERSHIP_SCHEME:-multicast}" /opt/wso2/repository/conf/axis2/axis2.xml
xmlstarlet edit --inplace -u "/axisconfig/clustering/parameter[@name='localMemberHost']" -v "${MULTICAST_PUBLISH_IP:-$PUBLIC_IP}" /opt/wso2/repository/conf/axis2/axis2.xml

# Insert the <parameter name="HostnameVerifier">AllowAll</parameter> element ...
# this is to allow the HTTPS requests passed through from the api-server to internal servers to allow any hostname
xmlstarlet edit --inplace -s "/axisconfig/transportSender[@name='https']" -t elem -n parameter -v "${HTTPS_HOSTNAME_VERIFIER:-DefaultAndLocalhost}" \
           -i "/axisconfig/transportSender[@name='https']/parameter[not(@name)]" -t attr -n name -v HostnameVerifier \
           /opt/wso2/repository/conf/axis2/axis2.xml


# Set the http proxy port if provided
xmlstarlet edit --inplace --delete "/Server/Service/Connector[not(@secure)]/@proxyPort" /opt/wso2/repository/conf/tomcat/catalina-server.xml
[ "${HTTP_PROXY_PORT}" != "" ] &&  xmlstarlet edit --inplace --insert "/Server/Service/Connector[not(@secure)]" --type attr -n proxyPort --value "${HTTP_PROXY_PORT}" /opt/wso2/repository/conf/tomcat/catalina-server.xml

# Set the https proxy port if provided
xmlstarlet edit --inplace --delete "/Server/Service/Connector[@secure='true']/@proxyPort" /opt/wso2/repository/conf/tomcat/catalina-server.xml
[ "${HTTPS_PROXY_PORT}" != "" ] &&  xmlstarlet edit --inplace --insert "/Server/Service/Connector[@secure='true']" --type attr -n proxyPort --value "${HTTPS_PROXY_PORT}" /opt/wso2/repository/conf/tomcat/catalina-server.xml

if [ "$PROFILE" != "" ]; then
    OPTS="-Dprofile=$PROFILE $OPTS"
fi

if [ -f "/opt/wso2/bin/extra.sh" ]; then
    chmod a+x /opt/wso2/bin/extra.sh
    /opt/wso2/bin/extra.sh
fi

/opt/wso2/bin/wso2server.sh "$@" "${OPTS}"
