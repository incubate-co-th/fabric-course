# Using Private Data in Fabric

[![Open this project in Cloud
Shell](http://gstatic.com/cloudssh/images/open-btn.png)](https://console.cloud.google.com/cloudshell/open?git_repo=https://github.com/incubate-co-th/fabric-course.git&page=editor&tutorial=private_data.md)

Channels are a private layer of communication between specific network members.

This tutorial follow the [Using Private Data in Fabric](https://hyperledger-fabric.readthedocs.io/en/release-2.3/private_data_tutorial.html#read-and-write-private-data-using-chaincode-apis) in Hyperledger Fabric document.

## Before you begin

Please follow steps in the tutorial by run the following command:
```bash
teachme prerequisites.md
```

## [Set up environment](https://hyperledger-fabric.readthedocs.io/en/release-2.3/private_data_tutorial.html#start-the-network)

### Clear the test network
```bash
cd fabric-samples/test-network
./network.sh down
```

### Start up the test network with couchDB
```bash
./network.sh up createChannel -ca -s couchdb -i 2.3.0
```

## [Deploy the private data smart contract to the channel](https://hyperledger-fabric.readthedocs.io/en/release-2.3/private_data_tutorial.html#deploy-the-private-data-smart-contract-to-the-channel)
```bash
./network.sh deployCC -ccn private -ccp ../asset-transfer-private-data/chaincode-go/ -ccl go -ccep "OR('Org1MSP.peer','Org2MSP.peer')" -cccg ../asset-transfer-private-data/chaincode-go/collections_config.json
```

There are command to approve with `--collections-config` flag. Find it on result in the terminal, no need to run it again.

```
peer lifecycle chaincode approveformyorg -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --channelID mychannel --name private --version 1.0 --collections-config ../asset-transfer-private-data/chaincode-go/collections_config.json --signature-policy "OR('Org1MSP.member','Org2MSP.member')" --package-id $CC_PACKAGE_ID --sequence 1 --tls --cafile $ORDERER_CA
```

And commit with `--collections-config` flag. Find it on result in the terminal, no need to run it again.

```
peer lifecycle chaincode commit -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --channelID mychannel --name private --version 1.0 --sequence 1 --collections-config ../asset-transfer-private-data/chaincode-go/collections_config.json --signature-policy "OR('Org1MSP.member','Org2MSP.member')" --tls --cafile $ORDERER_CA --peerAddresses localhost:7051 --tlsRootCertFiles $ORG1_CA --peerAddresses localhost:9051 --tlsRootCertFiles $ORG2_CA
```

## [Register identities](https://hyperledger-fabric.readthedocs.io/en/release-2.3/private_data_tutorial.html#register-identities)

### Set environment variable for the Org1
For the Fabric CA client:
```bash
export PATH=${PWD}/../bin:${PWD}:$PATH
export FABRIC_CFG_PATH=$PWD/../config/
```
For MSP home of the Org1:

```bash
export FABRIC_CA_CLIENT_HOME=${PWD}/organizations/peerOrganizations/org1.example.com/
```

### Register a new owner client identity

1. Create new owner account
```bash
fabric-ca-client register --caname ca-org1 --id.name owner --id.secret ownerpw --id.type client --tls.certfiles ${PWD}/organizations/fabric-ca/org1/tls-cert.pem
```

2. Enroll new owner
```bash
fabric-ca-client enroll -u https://owner:ownerpw@localhost:7054 --caname ca-org1 -M ${PWD}/organizations/peerOrganizations/org1.example.com/users/owner@org1.example.com/msp --tls.certfiles ${PWD}/organizations/fabric-ca/org1/tls-cert.pem
```

3. Copy the configuration file into the owner identity MSP folder
```bash
cp ${PWD}/organizations/peerOrganizations/org1.example.com/msp/config.yaml ${PWD}/organizations/peerOrganizations/org1.example.com/users/owner@org1.example.com/msp/config.yaml
```

### Register a new buyer client identity in the Org2
1. Set and environment variable
```bash
export FABRIC_CA_CLIENT_HOME=${PWD}/organizations/peerOrganizations/org2.example.com/
```

2. Create new buyer account
```bash
fabric-ca-client register --caname ca-org2 --id.name buyer --id.secret buyerpw --id.type client --tls.certfiles ${PWD}/organizations/fabric-ca/org2/tls-cert.pem
```

3. Enroll new buyer
```bash
fabric-ca-client enroll -u https://buyer:buyerpw@localhost:8054 --caname ca-org2 -M ${PWD}/organizations/peerOrganizations/org2.example.com/users/buyer@org2.example.com/msp --tls.certfiles ${PWD}/organizations/fabric-ca/org2/tls-cert.pem
```

3. Copy the configuration file into the buyer identity MSP folder
```bash
cp ${PWD}/organizations/peerOrganizations/org2.example.com/msp/config.yaml ${PWD}/organizations/peerOrganizations/org2.example.com/users/buyer@org2.example.com/msp/config.yaml
```

## [Create an asset in private data](https://hyperledger-fabric.readthedocs.io/en/release-2.3/private_data_tutorial.html#create-an-asset-in-private-data)

```bash
export PATH=${PWD}/../bin:$PATH
export FABRIC_CFG_PATH=$PWD/../config/
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID="Org1MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org1.example.com/users/owner@org1.example.com/msp
export CORE_PEER_ADDRESS=localhost:7051
```

```bash
export ASSET_PROPERTIES=$(echo -n '{"objectType":"asset","assetID":"asset1","color":"green","size":20,"appraisedValue":100}' | base64 -w 0)
peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile ${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem -C mychannel -n private -c '{"function":"CreateAsset","Args":[]}' --transient '{"asset_properties":"'$ASSET_PROPERTIES'"}'
```

## [Query the private data as an authorized peer](https://hyperledger-fabric.readthedocs.io/en/release-2.3/private_data_tutorial.html#query-the-private-data-as-an-authorized-peer)

Read the main details of the asset that was created by using the ReadAsset function to query the assetCollection collection as Org1
```bash
peer chaincode query -C mychannel -n private -c '{"function":"ReadAsset","Args":["asset1"]}'
```

The result should be:
```terminal
{"objectType":"asset","assetID":"asset1","color":"green","size":20,"owner":"x509::CN=appUser1,OU=admin,O=Hyperledger,ST=North Carolina,C=US::CN=ca.org1.example.com,O=org1.example.com,L=Durham,ST=North Carolina,C=US"}
```

Query for the appraisedValue private data of asset1 as a member of Org1
```bash
peer chaincode query -C mychannel -n private -c '{"function":"ReadAssetPrivateDetails","Args":["Org1MSPPrivateCollection","asset1"]}'
```
The result should be:
```terminal
{"assetID":"asset1","appraisedValue":100}
```

## [Query the private data as an unauthorized peer](https://hyperledger-fabric.readthedocs.io/en/release-2.3/private_data_tutorial.html#query-the-private-data-as-an-unauthorized-peer)


### [Switch to a peer in Org2](https://hyperledger-fabric.readthedocs.io/en/release-2.3/private_data_tutorial.html#switch-to-a-peer-in-org2)
```bash
export CORE_PEER_LOCALMSPID="Org2MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org2.example.com/users/buyer@org2.example.com/msp
export CORE_PEER_ADDRESS=localhost:9051
```
### [Query private data Org2 is authorized to](https://hyperledger-fabric.readthedocs.io/en/release-2.3/private_data_tutorial.html#query-private-data-org2-is-authorized-to)
```bash
peer chaincode query -C mychannel -n private -c '{"function":"ReadAsset","Args":["asset1"]}'
```

The result should be:
```terminal
{"objectType":"asset","assetID":"asset1","color":"green","size":20,
"owner":"x509::CN=appUser1,OU=admin,O=Hyperledger,ST=North Carolina,C=US::CN=ca.org1.example.com,O=org1.example.com,L=Durham,ST=North Carolina,C=US" }
```

### [Query private data Org2 is not authorized to](https://hyperledger-fabric.readthedocs.io/en/release-2.3/private_data_tutorial.html#query-private-data-org2-is-not-authorized-to)

1. Confirm that the asset’s appraisedValue is not stored in the Org2MSPPrivateCollection on the Org2 peer
```bash
peer chaincode query -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile ${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem -C mychannel -n private -c '{"function":"ReadAssetPrivateDetails","Args":["Org2MSPPrivateCollection","asset1"]}'
```

The empty response shows that the asset1 private details do not exist in buyer (Org2) private collection.

2. Confirm that a user from Org2 cannot read the Org1 private data collection

```bash
peer chaincode query -C mychannel -n private -c '{"function":"ReadAssetPrivateDetails","Args":["Org1MSPPrivateCollection","asset1"]}'
```
The error should be:
```terminal
Error: endorsement failure during query. response: status:500 message:"failed to
read asset details: GET_STATE failed: transaction ID: d23e4bc0538c3abfb7a6bd4323fd5f52306e2723be56460fc6da0e5acaee6b23: tx
creator does not have read access permission on privatedata in chaincodeName:private collectionName: Org1MSPPrivateCollection"
```

## [Transfer the Asset](https://hyperledger-fabric.readthedocs.io/en/release-2.3/private_data_tutorial.html#transfer-the-asset)

To transfer an asset, the buyer (recipient) needs to agree to the same `appraisedValue` as the asset owner, by calling chaincode function `AgreeToTransfer`. The agreed value will be stored in the `Org2MSPDetailsCollection` collection on the Org2 peer. Run the following commands to agree to the appraised value of `100` as Org2:

```bash
export ASSET_VALUE=$(echo -n '{"assetID":"asset1","appraisedValue":100}' | base64 -w 0)
peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile ${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem -C mychannel -n private -c '{"function":"AgreeToTransfer","Args":[]}' --transient '{"asset_value":"'$ASSET_VALUE'"}'
```

The buyer can now query the value they agreed to in the Org2 private data collection:
```bash
peer chaincode query -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile ${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem -C mychannel -n private -c '{"function":"ReadAssetPrivateDetails","Args":["Org2MSPPrivateCollection","asset1"]}'
```

And the result should be:
```terminal
{"assetID":"asset1","appraisedValue":100}
```

## [Purge Private Data(Optional)](https://hyperledger-fabric.readthedocs.io/en/release-2.3/private_data_tutorial.html#purge-private-data)

For use cases where private data only needs to be persisted for a short period of time, it is possible to “purge” the data after a certain set number of blocks, leaving behind only a hash of the data that serves as immutable evidence of the transaction.

## [Using indexes with private data(Optional)](https://hyperledger-fabric.readthedocs.io/en/release-2.3/private_data_tutorial.html#using-indexes-with-private-data)
Indexes can also be applied to private data collections, by packaging indexes in the `META-INF/statedb/couchdb/collections/<collection_name>/indexes` directory alongside the chaincode.

[indexOwner.json](https://github.com/hyperledger/fabric-samples/blob/master//asset-transfer-private-data/chaincode-go/META-INF/statedb/couchdb/collections/assetCollection/indexes/indexOwner.json) in `assetCollection/indexes`
```json
{
    "index": {
      "fields": [
        "objectType",
        "owner"
      ]
    },
    "ddoc": "indexOwnerDoc",
    "name": "indexOwner",
    "type": "json"
}
```

## [Clean up](https://hyperledger-fabric.readthedocs.io/en/release-2.3/private_data_tutorial.html#clean-up)

Bring down the network
```bash
./network.sh down
```
