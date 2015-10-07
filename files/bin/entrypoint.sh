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

# Create tmp file
tmp=`mktemp -t "entrypoint.XXXXXXXXXX"`

# Read in the environment variables first (they take priority)
getEnvironmentVarsAsProperties >> $tmp

# Read in the app.properties file
[ -f /opt/wso2/app.properties ] && cat /opt/wso2/app.properties >> $tmp

# Read in the default.properties file
[ -f /opt/wso2/default.properties ] && cat /opt/wso2/default.properties >> $tmp

# Run the $tmp file through the property-parser to produce java property arguments
OPTS=`java -jar /opt/wso2/bin/property-parser-1.0.jar $tmp`

# Remove the tmp file
rm $tmp

# Overlay everything from /extra into /opt/wso2
if [ -d /extra ] && [ "`ls -A /extra`" ]; then
    cp -R /extra/* /opt/wso2/
fi

/opt/wso2/bin/wso2server.sh "$@" "${OPTS}"
