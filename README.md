# docker-wso2is
Dockerfile for WSO2 Identity Server

This runs the default instance of the wso2 identity server 5.0.0 pre-packaged with the api manager 1.9.1 key manager.

This was downloaded from [here](https://docs.wso2.com/display/CLUSTER420/Configuring+the+Pre-Packaged+Identity+Server+5.0.0+with+API+Manager+1.9.1)


### Well Known Addresses (WKA) Clustering

Passing an environment variable like this:

```
WELL_KNOWN_ADDRESSES=worker1.local:4000 worker2.local:4000
```

Would add something like the following to the well known addresses

```
<member>
    <hostName>worker1.local</hostName>
    <port>4000</port>
</member>
<member>
    <hostName>worker2.local</hostName>
    <port>4000</port>
</member>
```
