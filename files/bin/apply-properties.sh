#!/bin/bash

CARBON_HOME=${CARBON_HOME:-./}
PROP_FILE="$1"

template () {
    java -jar "${CARBON_HOME}/bin/property-parser.jar" template "$1"
}

get-prop () {
    echo "\${$1}" | java -jar "${CARBON_HOME}/bin/property-parser.jar" template "$2"
}

set-value () {
    XPATH=${1}
    PROP_NAME=${2}
    FILE=${3}
    NAMESPACE=${4:-'c=http://wso2.org/projects/carbon/carbon.xml'}
    VALUE=`echo "${PROP_NAME}" | template "${PROP_FILE}"`
    xmlstarlet edit --inplace \
        -N ${NAMESPACE} \
        --update "${XPATH}" \
        --value "${VALUE}" \
        "${FILE}"
}

insert-elem-before () {
    XPATH=${1}
    NAME=${2}
    PROP_NAME=${3}
    FILE=${4}
    NAMESPACE=${5:-'c=http://wso2.org/projects/carbon/carbon.xml'}
    VALUE=`echo "${PROP_NAME}" | template "${PROP_FILE}"`
    xmlstarlet edit --inplace \
        -N ${NAMESPACE} \
        --insert "${XPATH}" \
        --type elem \
        --name "${NAME}" \
        --value "${VALUE}" \
        "${FILE}"
}

#################################
# repository/conf/api-manager.xml
#################################

NAMESPACE=
FILE="${CARBON_HOME}/repository/conf/api-manager.xml"
echo Updating $FILE with configuration properties

set-value '/APIManager/GatewayType' '${APIManager_GatewayType}' "$FILE"
set-value '/APIManager/AuthManager/ServerURL' '${APIManager_AuthManager_ServerURL}' "$FILE" # maybe make this one conditional?
set-value '/APIManager/APIConsumerAuthentication/SecurityContextHeader' '${APIManager_APIConsumerAuthentication_SecurityContextHeader}' "$FILE"
insert-elem-before '/APIManager/APIConsumerAuthentication/TokenGeneratorImpl' 'ClaimsRetrieverImplClass' '${APIManager_APIConsumerAuthentication_ClaimsRetrieverImplClass}' "$FILE"
insert-elem-before '/APIManager/APIConsumerAuthentication/TokenGeneratorImpl' 'ConsumerDialectURI' '${APIManager_APIConsumerAuthentication_ConsumerDialectURI}' "$FILE"
insert-elem-before '/APIManager/APIConsumerAuthentication/TokenGeneratorImpl' 'SignatureAlgorithm' '${APIManager_APIConsumerAuthentication_SignatureAlgorithm}' "$FILE"
insert-elem-before '/APIManager/APIConsumerAuthentication/TokenGeneratorImpl' 'EnableTokenGeneration' '${APIManager_APIConsumerAuthentication_EnableTokenGeneration}' "$FILE"
set-value '/APIManager/APIConsumerAuthentication/TokenGeneratorImpl' '${APIManager_APIConsumerAuthentication_TokenGeneratorImpl}' "$FILE"
set-value '/APIManager/APIGateway/Environments/Environment[@type="hybrid"]/ServerURL' '${APIManager_APIGateway_Environment_hybrid_ServerURL}' "$FILE"
set-value '/APIManager/APIGateway/Environments/Environment[@type="hybrid"]/GatewayEndpoint' '${APIManager_APIGateway_Environment_hybrid_GatewayEndpoint}' "$FILE"
set-value '/APIManager/APIGateway/EnableGatewayKeyCache' '${APIManager_APIGateway_EnableGatewayKeyCache}' "$FILE"
set-value '/APIManager/APIGateway/EnableGatewayResourceCache' '${APIManager_APIGateway_EnableGatewayResourceCache}' "$FILE"
set-value '/APIManager/APIKeyValidator/ServerURL' '${APIManager_APIKeyValidator_ServerURL}' "$FILE" # maybe make this one conditional?
set-value '/APIManager/APIKeyValidator/EnableJWTCache' '${APIManager_APIKeyValidator_EnableJWTCache}' "$FILE"
set-value '/APIManager/APIKeyValidator/EnableKeyMgtValidationInfoCache' '${APIManager_APIKeyValidator_EnableKeyMgtValidationInfoCache}' "$FILE"
set-value '/APIManager/APIKeyValidator/KeyValidatorClientType' '${APIManager_APIKeyValidator_KeyValidatorClientType}' "$FILE"
set-value '/APIManager/APIKeyValidator/ThriftClientPort' '${APIManager_APIKeyValidator_ThriftClientPort}' "$FILE"
set-value '/APIManager/APIKeyValidator/ThriftClientConnectionTimeOut' '${APIManager_APIKeyValidator_ThriftClientConnectionTimeOut}' "$FILE"
set-value '/APIManager/APIKeyValidator/ThriftServerPort' '${APIManager_APIKeyValidator_ThriftServerPort}' "$FILE"
insert-elem-before '/APIManager/APIKeyValidator/EnableThriftServer' 'ThriftServerHost' '${APIManager_APIKeyValidator_ThriftServerHost}' "$FILE"
set-value '/APIManager/APIKeyValidator/EnableThriftServer' '${APIManager_APIKeyValidator_EnableThriftServer}' "$FILE"
set-value '/APIManager/APIKeyValidator/ApplicationTokenScope' '${APIManager_APIKeyValidator_ApplicationTokenScope}' "$FILE"
set-value '/APIManager/APIKeyValidator/KeyValidationHandlerClassName' '${APIManager_APIKeyValidator_KeyValidationHandlerClassName}' "$FILE"
insert-elem-before '/APIManager/APIKeyValidator/TokenEndPointName' 'RemoveUserNameFromJWTForApplicationToken' '${APIManager_APIKeyValidator_RemoveUserNameFromJWTForApplicationToken}' "$FILE"
set-value '/APIManager/APIKeyValidator/TokenEndPointName' '${APIManager_APIKeyValidator_TokenEndPointName}' "$FILE"
set-value '/APIManager/APIKeyValidator/RevokeAPIURL' '${APIManager_APIKeyValidator_RevokeAPIURL}' "$FILE" # maybe make this one conditional?
set-value '/APIManager/APIKeyValidator/EncryptPersistedTokens' '${APIManager_APIKeyValidator_EncryptPersistedTokens}' "$FILE"
set-value '/APIManager/TierManagement/EnableUnlimitedTier' '${APIManager_APIKeyValidator_TierManagement_EnableUnlimitedTier}' "$FILE"


############################
# repository/conf/carbon.xml
############################

NAMESPACE='c=http://wso2.org/projects/carbon/carbon.xml'
FILE="${CARBON_HOME}/repository/conf/carbon.xml"
echo Updating $FILE with configuration properties

set-value '/c:Server/c:HostName' '${Server_HostName}' "$FILE" "$NAMESPACE"
set-value '/c:Server/c:MgtHostName' '${Server_MgtHostName}' "$FILE" "$NAMESPACE"
set-value '/c:Server/c:Axis2Config/c:HideAdminServiceWSDLs' '${HIDE_ADMIN_SERVICE_WSDLS}' "$FILE" "$NAMESPACE"
insert-elem-before '/c:Server/c:Security' 'EnableEmailUserName' '${Server_EnableEmailUserName}' "$FILE" "$NAMESPACE"
set-value '/c:Server/c:Security/c:KeyStore/c:Location' '${carbon.home}/${KeyStore_Primary_Location}' "$FILE" "$NAMESPACE"
set-value '/c:Server/c:Security/c:KeyStore/c:Type' '${KeyStore_Primary_Type}' "$FILE" "$NAMESPACE"
set-value '/c:Server/c:Security/c:KeyStore/c:Password' '${KeyStore_Primary_Password}' "$FILE" "$NAMESPACE"
set-value '/c:Server/c:Security/c:KeyStore/c:KeyAlias' '${KeyStore_Primary_KeyAlias}' "$FILE" "$NAMESPACE"
set-value '/c:Server/c:Security/c:KeyStore/c:KeyPassword' '${KeyStore_Primary_KeyPassword}' "$FILE" "$NAMESPACE"
set-value '/c:Server/c:Security/c:RegistryKeyStore/c:Location' '${carbon.home}/${KeyStore_Registry_Location}' "$FILE" "$NAMESPACE"
set-value '/c:Server/c:Security/c:RegistryKeyStore/c:Type' '${KeyStore_Registry_Type}' "$FILE" "$NAMESPACE"
set-value '/c:Server/c:Security/c:RegistryKeyStore/c:Password' '${KeyStore_Registry_Password}' "$FILE" "$NAMESPACE"
set-value '/c:Server/c:Security/c:RegistryKeyStore/c:KeyAlias' '${KeyStore_Registry_KeyAlias}' "$FILE" "$NAMESPACE"
set-value '/c:Server/c:Security/c:RegistryKeyStore/c:KeyPassword' '${KeyStore_Registry_KeyPassword}' "$FILE" "$NAMESPACE"
set-value '/c:Server/c:Security/c:TrustStore/c:Location' '${carbon.home}/${TrustStore_Location}' "$FILE" "$NAMESPACE"
set-value '/c:Server/c:Security/c:TrustStore/c:Type' '${TrustStore_Type}' "$FILE" "$NAMESPACE"
set-value '/c:Server/c:Security/c:TrustStore/c:Password' '${TrustStore_Password}' "$FILE" "$NAMESPACE"
set-value '/c:Server/c:DeploymentSynchronizer/c:Enabled' '${Server_DeploymentSynchronizer_Enabled}' "$FILE" "$NAMESPACE"
set-value '/c:Server/c:DeploymentSynchronizer/c:AutoCommit' '${Server_DeploymentSynchronizer_AutoCommit}' "$FILE" "$NAMESPACE"
set-value '/c:Server/c:DeploymentSynchronizer/c:AutoCheckout' '${Server_DeploymentSynchronizer_AutoCheckout}' "$FILE" "$NAMESPACE"
set-value '/c:Server/c:DeploymentSynchronizer/c:RepositoryType' '${Server_DeploymentSynchronizer_RepositoryType}' "$FILE" "$NAMESPACE"
set-value '/c:Server/c:DeploymentSynchronizer/c:SvnUrl' '${Server_DeploymentSynchronizer_SvnUrl}' "$FILE" "$NAMESPACE"
set-value '/c:Server/c:DeploymentSynchronizer/c:SvnUser' '${Server_DeploymentSynchronizer_SvnUser}' "$FILE" "$NAMESPACE"
set-value '/c:Server/c:DeploymentSynchronizer/c:SvnPassword' '${Server_DeploymentSynchronizer_SvnPassword}' "$FILE" "$NAMESPACE"
set-value '/c:Server/c:DeploymentSynchronizer/c:SvnUrlAppendTenantId' '${Server_DeploymentSynchronizer_SvnUrlAppendTenantId}' "$FILE" "$NAMESPACE"


##############################
# repository/conf/identity.xml
##############################

NAMESPACE='c=http://wso2.org/projects/carbon/carbon.xml'
FILE="${CARBON_HOME}/repository/conf/identity.xml"
echo Updating $FILE with configuration properties

insert-elem-before '/c:Server/c:JDBCPersistenceManager/c:DataSource' 'SkipDBSchemaCreation' '${Server_JDBCPersistenceManager_SkipDBSchemaCreation}' "$FILE"
set-value '/c:Server/c:Security/c:UserTrustedRPStore/c:Location' '${carbon.home}/${KeyStore_UserRP_Location}' "$FILE"
set-value '/c:Server/c:Security/c:UserTrustedRPStore/c:Type' '${KeyStore_UserRP_Type}' "$FILE"
set-value '/c:Server/c:Security/c:UserTrustedRPStore/c:Password' '${KeyStore_UserRP_Password}' "$FILE"
insert-elem-before '/c:Server/c:Security/c:UserTrustedRPStore/c:KeyPassword' 'KeyAlias' '${KeyStore_UserRP_KeyAlias}' "$FILE"
set-value '/c:Server/c:Security/c:UserTrustedRPStore/c:KeyPassword' '${KeyStore_UserRP_KeyPassword}' "$FILE"
set-value '/c:Server/c:EntitlementSettings/c:ThirftBasedEntitlementConfig/c:KeyStore/c:Location' '${carbon.home}/${KeyStore_Primary_Location}' "$FILE"
set-value '/c:Server/c:EntitlementSettings/c:ThirftBasedEntitlementConfig/c:KeyStore/c:Password' '${KeyStore_Primary_Password}' "$FILE"


##############################
# repository/conf/registry.xml
##############################

NAMESPACE='c=http://wso2.org/projects/carbon/carbon.xml'
FILE="${CARBON_HOME}/repository/conf/registry.xml"
echo Updating $FILE with configuration properties

#set-value '' '' "$FILE"

##############################
# repository/conf/user-mgt.xml
##############################

NAMESPACE='c=http://wso2.org/projects/carbon/carbon.xml'
FILE="${CARBON_HOME}/repository/conf/user-mgt.xml"
echo Updating $FILE with configuration properties

#set-value '' '' "$FILE"