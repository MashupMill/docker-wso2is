FROM java:7

ENV JAVA_HOME=/usr/lib/jvm/java-7-openjdk-amd64 \
    CARBON_HOME=/opt/wso2

# This is the pre-packaged identity server 5.0.0 with api manager 1.9.1
# Came from https://docs.wso2.com/display/CLUSTER420/Configuring+the+Pre-Packaged+Identity+Server+5.0.0+with+API+Manager+1.9.1
ADD wso2is-5.0.0.zip /opt/

RUN apt-get update && \
    apt-get install -y zip xmlstarlet && \
    apt-get clean && \
    unzip /opt/wso2is-5.0.0.zip -d /opt && \
    mv /opt/wso2is-5.0.0 /opt/wso2 && \
    rm /opt/wso2is-5.0.0.zip

WORKDIR /opt/wso2/
EXPOSE 9443
CMD ["/opt/wso2/bin/wso2server.sh"]
