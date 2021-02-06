# Genesis Block
[![Open this project in Cloud
Shell](http://gstatic.com/cloudssh/images/open-btn.png)](https://console.cloud.google.com/cloudshell/open?git_repo=https://github.com/incubate-co-th/fabric-course.git&page=editor&tutorial=first-orderer.md)

After create the genesis block in Hyperledger Fabric, the tool [osnadmin](https://hyperledger-fabric.readthedocs.io/en/release-2.3/commands/osnadminchannel.html) are used to create a channel with created genesis block and join the orderer to a channel.

This tutorial adapt from [Create a channel without a system channel](https://hyperledger-fabric.readthedocs.io/en/release-2.3/create_channel/create_channel_participation.html#set-up-the-configtxgen-tool) in Hyperledger Fabric document.

## Before you begin

Please follow steps in the tutorial by run the following command to download `fabric-samples` folder form github:
```bash
teachme prerequisites.md
```

Start test network and create a genesis block using the tutorial:
```bash
teachme genesis.md
```

## [`osnadmin channel join`](https://hyperledger-fabric.readthedocs.io/en/release-2.3/commands/osnadminchannel.html#osnadmin-channel-join) are used to create a channel and join the orderer to the created channel

```bash
osnadmin channel join --channel-id mychannel --config-block ./channel-artifacts/mychannel.block -o localhost:7053 --ca-file ${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem --client-cert ${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/tls/server.crt --client-key ${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/tls/server.key
```
The result should be:
```terminal
Status: 201
{
        "name": "mychannel",
        "url": "/participation/v1/channels/mychannel",
        "consensusRelation": "consenter",
        "status": "active",
        "height": 1
}
```

## List all the channel by [`osnadmin channel list`] (https://hyperledger-fabric.readthedocs.io/en/release-2.3/commands/osnadminchannel.html#osnadmin-channel-list) command

```bash
osnadmin channel list -o localhost:7053 --ca-file ${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem --client-cert ${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/tls/server.crt --client-key ${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/tls/server.key
```
The result should be:
```terminal
Status: 200
{
        "systemChannel": null,
        "channels": [
                {
                        "name": "mychannel",
                        "url": "/participation/v1/channels/mychannel"
                }
        ]
}
```
If specific channel Id as:
```bash
osnadmin channel list -o localhost:7053 --channel-id mychannel --ca-file ${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem --client-cert ${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/tls/server.crt --client-key ${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/tls/server.key
```
The result will be:
```terminal
Status: 200
{
        "name": "mychannel",
        "url": "/participation/v1/channels/mychannel",
        "consensusRelation": "consenter",
        "status": "active",
        "height": 1
}
```
