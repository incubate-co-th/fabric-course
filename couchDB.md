# Using CouchDB

[![Open this project in Cloud
Shell](http://gstatic.com/cloudssh/images/open-btn.png)](https://console.cloud.google.com/cloudshell/open?git_repo=https://github.com/incubate-co-th/fabric-course.git&page=editor&tutorial=couchDB.md)

Channels are a private layer of communication between specific network members.

This tutorial follow the [Using CouchDB](https://hyperledger-fabric.readthedocs.io/en/release-2.3/couchdb_tutorial.html) in Hyperledger Fabric document.

## Before you begin

Please follow steps in the tutorial by run the following command:
```bash
teachme prerequisites.md
```

## [Start the network](https://hyperledger-fabric.readthedocs.io/en/release-2.3/couchdb_tutorial.html#start-the-network)

Bring down the network
```bash
cd fabric-samples/test-network
./network.sh down
export PATH=${PWD}/../bin:${PWD}:$PATH
export FABRIC_CFG_PATH=$PWD/../config/
```

Vendor the chaincode dependencies before we can deploy it to the network
```bash
cd ../asset-transfer-ledger-queries/chaincode-go
GO111MODULE=on go mod vendor
cd ../../test-network
```

Start the test network
```bash
./network.sh up createChannel -s couchdb -i 2.3.0
```

## [Deploy the smart contract](https://hyperledger-fabric.readthedocs.io/en/release-2.3/couchdb_tutorial.html#deploy-the-smart-contract)
```bash
./network.sh deployCC -ccn ledger -ccp ../asset-transfer-ledger-queries/chaincode-go/ -ccl go -ccep "OR('Org1MSP.peer','Org2MSP.peer')"
```
### [Verify index was deployed](https://hyperledger-fabric.readthedocs.io/en/release-2.3/couchdb_tutorial.html#verify-index-was-deployed)

```bash
docker logs peer0.org1.example.com  2>&1 | grep "CouchDB index"
```
A result should be:

```terminal
[couchdb] createIndex -> INFO 072 Created CouchDB index [indexOwner] in state database [mychannel_ledger] using design document [_design/indexOwnerDoc]
```

## [Query the CouchDB State Database](https://hyperledger-fabric.readthedocs.io/en/release-2.3/couchdb_tutorial.html#query-the-couchdb-state-database)

### [Run the query using the peer command](https://hyperledger-fabric.readthedocs.io/en/release-2.3/couchdb_tutorial.html#run-the-query-using-the-peer-command)
```bash
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID="Org1MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
export CORE_PEER_ADDRESS=localhost:7051
peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile ${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem -C mychannel -n ledger -c '{"Args":["CreateAsset","asset1","blue","5","tom","35"]}'
```

Because the command has backslash `\`, the auto-populate feature cannot used. Copy the command, paste to the terminal and click enter. 
```
peer chaincode query -C mychannel -n ledger -c '{"Args":["QueryAssets", "{\"selector\":{\"docType\":\"asset\",\"owner\":\"tom\"}, \"use_index\":[\"_design/indexOwnerDoc\", \"indexOwner\"]}"]}'
```
The result should be:
```terminal
[{"docType":"asset","ID":"asset1","color":"blue","size":5,"owner":"tom","appraisedValue":35}]
```

## [Use best practices for queries and indexes](https://hyperledger-fabric.readthedocs.io/en/release-2.3/couchdb_tutorial.html#use-best-practices-for-queries-and-indexes)

Because the command has backslash `\`, the auto-populate feature cannot used. Copy the command, paste to the terminal and click enter. 

### Example one: query fully supported by the index
```
export CHANNEL_NAME=mychannel
time peer chaincode query -C $CHANNEL_NAME -n ledger -c '{"Args":["QueryAssets", "{\"selector\":{\"docType\":\"asset\",\"owner\":\"tom\"}, \"use_index\":[\"indexOwnerDoc\", \"indexOwner\"]}"]}'
```

### Example two: query fully supported by the index with additional data
```
time peer chaincode query -C $CHANNEL_NAME -n ledger -c '{"Args":["QueryAssets", "{\"selector\":{\"docType\":\"asset\",\"owner\":\"tom\",\"color\":\"blue\"}, \"use_index\":[\"/indexOwnerDoc\", \"indexOwner\"]}"]}'
```

### Example three: query not supported by the index
```
time peer chaincode query -C $CHANNEL_NAME -n ledger -c '{"Args":["QueryAssets", "{\"selector\":{\"owner\":\"tom\"}, \"use_index\":[\"indexOwnerDoc\", \"indexOwner\"]}"]}'
```
### Example four: query with $or supported by the index
```
time peer chaincode query -C $CHANNEL_NAME -n ledger -c '{"Args":["QueryAssets", "{\"selector\":{\"$or\":[{\"docType\":\"asset\"},{\"owner\":\"tom\"}]}, \"use_index\":[\"indexOwnerDoc\", \"indexOwner\"]}"]}'
```
### Example five: Query with $or not supported by the index
```
time peer chaincode query -C $CHANNEL_NAME -n ledger -c '{"Args":["QueryAssets", "{\"selector\":{\"$or\":[{\"docType\":\"asset\",\"owner\":\"tom\"},{\"color\":\"yellow\"}]}, \"use_index\":[\"indexOwnerDoc\", \"indexOwner\"]}"]}'
```

### Compare 5 examples
Because the data is small, the complexities does not shown in the result. But the result should be 5 >= 4 >= 3 >= 2 >= 1 

## [Query the CouchDB State Database With Pagination](https://hyperledger-fabric.readthedocs.io/en/release-2.3/couchdb_tutorial.html#query-the-couchdb-state-database-with-pagination)

Create four more assets owned by "tom":
```bash
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID="Org1MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
export CORE_PEER_ADDRESS=localhost:7051
peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile  ${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem -C mychannel -n ledger -c '{"Args":["CreateAsset","asset2","yellow","5","tom","35"]}'
peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile  ${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem -C mychannel -n ledger -c '{"Args":["CreateAsset","asset3","green","6","tom","20"]}'
peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile  ${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem -C mychannel -n ledger -c '{"Args":["CreateAsset","asset4","purple","7","tom","20"]}'
peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile  ${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem -C mychannel -n ledger -c '{"Args":["CreateAsset","asset5","blue","8","tom","40"]}'
```

Calls `QueryAssetsWithPagination` with a `pageSize` of 3 and no `bookmark` specified, copy&paste the command to terminal and click enter:
```
peer chaincode query -C mychannel -n ledger -c '{"Args":["QueryAssetsWithPagination", "{\"selector\":{\"docType\":\"asset\",\"owner\":\"tom\"}, \"use_index\":[\"_design/indexOwnerDoc\", \"indexOwner\"]}","3",""]}'
```

Call `QueryAssetsWithPagination` with a `pageSize` of 3, includes the `bookmark` returned from the previous query.
```
peer chaincode query -C $CHANNEL_NAME -n ledger -c '{"Args":["QueryAssetsWithPagination", "{\"selector\":{\"docType\":\"asset\",\"owner\":\"tom\"}, \"use_index\":[\"_design/indexOwnerDoc\", \"indexOwner\"]}","3","g1AAAABJeJzLYWBgYMpgSmHgKy5JLCrJTq2MT8lPzkzJBYqzJRYXp5YYg2Q5YLI5IPUgSVawJIjFXJKfm5UFANozE8s"]}'
```
The result will be:
```json
{
  "records":[
    {"docType":"asset","ID":"asset4","color":"purple","size":7,"owner":"tom","appraisedValue":20},
    {"docType":"asset","ID":"asset5","color":"blue","size":8,"owner":"tom","appraisedValue":40}],
  "fetchedRecordsCount":2,
  "bookmark":"g1AAAABJeJzLYWBgYMpgSmHgKy5JLCrJTq2MT8lPzkzJBYqzJRYXp5aYgmQ5YLI5IPUgSVawJIjFXJKfm5UFANqBE80"
}
```
Call `QueryAssetsWithPagination` with a `pageSize` of 3, includes the `bookmark` returned from the previous query, but no more results will get returned
```
peer chaincode query -C $CHANNEL_NAME -n ledger -c '{"Args":["QueryAssetsWithPagination", "{\"selector\":{\"docType\":\"asset\",\"owner\":\"tom\"}, \"use_index\":[\"_design/indexOwnerDoc\", \"indexOwner\"]}","3","g1AAAABJeJzLYWBgYMpgSmHgKy5JLCrJTq2MT8lPzkzJBYqzJRYXp5aYgmQ5YLI5IPUgSVawJIjFXJKfm5UFANqBE80"]}'
```

## [Update an Index](https://hyperledger-fabric.readthedocs.io/en/release-2.3/couchdb_tutorial.html#update-an-index)

### [Iterating on your index definition](https://hyperledger-fabric.readthedocs.io/en/release-2.3/couchdb_tutorial.html#iterating-on-your-index-definition)
The cURL command to create index:
```
curl -i -X POST -H "Content-Type: application/json" -d "{\"index\":{\"fields\":[\"docType\",\"owner\"]},\"name\":\"indexOwner\",\"ddoc\":\"indexOwnerDoc\",\"type\":\"json\"}" http://admin:adminpw@localhost:5984/mychannel_ledger/_index
```

## [Delete an Index](https://hyperledger-fabric.readthedocs.io/en/release-2.3/couchdb_tutorial.html#delete-an-index)

The cURL command to delete the index used in this tutorial would be:

```bash
curl -X DELETE http://admin:adminpw@localhost:5984/mychannel_ledger/_index/indexOwnerDoc/json/indexOwner -H  "accept: */*" -H  "Host: localhost:5984"
```
## [Clean up](https://hyperledger-fabric.readthedocs.io/en/release-2.3/couchdb_tutorial.html#clean-up)
```bash
./network.sh down
```
