# Secured asset transfer in Fabric

[![Open this project in Cloud
Shell](http://gstatic.com/cloudssh/images/open-btn.png)](https://console.cloud.google.com/cloudshell/open?git_repo=https://github.com/incubate-co-th/fabric-course.git&page=editor&tutorial=secured_transfer.md)

Channels are a private layer of communication between specific network members.

This tutorial follow the [Secured asset transfer in Fabric](https://hyperledger-fabric.readthedocs.io/en/release-2.3/secured_asset_transfer/secured_private_asset_transfer_tutorial.html) in Hyperledger Fabric document.

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
./network.sh up createChannel -i 2.3.0
```

## [Deploy the smart contract](https://hyperledger-fabric.readthedocs.io/en/release-2.3/secured_asset_transfer/secured_private_asset_transfer_tutorial.html#deploy-the-smart-contract)

Deploy the `asset-transfer-secured-agreement` in golang with endorsement policy of `OR('Org1MSP.peer','Org2MSP.peer')`
```bash
./network.sh deployCC -ccn secured -ccp ../asset-transfer-secured-agreement/chaincode-go/ -ccl go -ccep "OR('Org1MSP.peer','Org2MSP.peer')"
```


### [Set the environment variables to operate as Org1](https://hyperledger-fabric.readthedocs.io/en/release-2.3/secured_asset_transfer/secured_private_asset_transfer_tutorial.html#set-the-environment-variables-to-operate-as-org1)


To make the interaction with the network as both Org1 and Org2 easier, separate terminals are used for each organization. Open a new terminal and make sure that the operating is in the `test-network` directory. Set the following environment variables to operate the peer CLI as the Org1 admin:

```bash
export PATH=${PWD}/../bin:${PWD}:$PATH
export FABRIC_CFG_PATH=$PWD/../config/
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID="Org1MSP"
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
export CORE_PEER_ADDRESS=localhost:7051
```


### [Set the environment variables to operate as Org2](https://hyperledger-fabric.readthedocs.io/en/release-2.3/secured_asset_transfer/secured_private_asset_transfer_tutorial.html#set-the-environment-variables-to-operate-as-org2)

For the other terminal, after make sure that this terminal is also operating from the `test-network` directory, set the following environment variables to operate as the Org2 admin:
```bash
export PATH=${PWD}/../bin:${PWD}:$PATH
export FABRIC_CFG_PATH=$PWD/../config/
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID="Org2MSP"
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt
export CORE_PEER_ADDRESS=localhost:9051
```

Now there are 2 terminals that operate to `Org1` and `Org2`.

## [Create an asset](https://hyperledger-fabric.readthedocs.io/en/release-2.3/secured_asset_transfer/secured_private_asset_transfer_tutorial.html#create-an-asset)

### [Operate from the Org1 terminal](https://hyperledger-fabric.readthedocs.io/en/release-2.3/secured_asset_transfer/secured_private_asset_transfer_tutorial.html#operate-from-the-org1-terminal)

Issue the following command to create a JSON that describe the asset encoded in Base64 format, which will be passed to the creation transaction as transient data. The `"salt"` parameter is a random string that would prevent another member of the channel from guessing the asset using the hash on the ledger.

```bash
export ASSET_PROPERTIES=$(echo -n '{"object_type":"asset_properties","asset_id":"asset1","color":"blue","size":35,"salt":"a94a8fe5ccb19ba61c4c0873d391e987982fbbd3"}' | base64  -w 0)
```

Then create a asset that belongs to Org1:

```bash
peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile ${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem -C mychannel -n secured -c '{"function":"CreateAsset","Args":["asset1", "A new asset for Org1MSP"]}' --transient '{"asset_properties":"'$ASSET_PROPERTIES'"}'
```

The result will be:
```terminal
[chaincodeCmd] chaincodeInvokeOrQuery -> INFO 001 Chaincode invoke successful. result: status:200
```

Query the Org1 implicit data collection to see the asset that was created:
```bash
peer chaincode query -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile ${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem -C mychannel -n secured -c '{"function":"GetAssetPrivateProperties","Args":["asset1"]}'
```

The result will be:
```terminal
{"object_type":"asset_properties","asset_id":"asset1","color":"blue","size":35,"salt":"a94a8fe5ccb19ba61c4c0873d391e987982fbbd3"}
```

Query the ledger to see the public ownership record:
```bash
peer chaincode query -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile ${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem -C mychannel -n secured -c '{"function":"ReadAsset","Args":["asset1"]}'
```

The result will be:
```terminal
{"object_type":"asset","asset_id":"asset1","owner_org":"Org1MSP","public_description":"A new asset for Org1MSP"}
```

Change the asset description to put the asset up for sale:
```bash
peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile ${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem -C mychannel -n secured -c '{"function":"ChangePublicDescription","Args":["asset1","This asset is for sale"]}'
```

The result will be:
```terminal
[chaincodeCmd] chaincodeInvokeOrQuery -> INFO 001 Chaincode invoke successful. result: status:200
```

Query the ledger again to see the updated description:
```bash
peer chaincode query -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile ${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem -C mychannel -n secured -c '{"function":"ReadAsset","Args":["asset1"]}'
```

The result will be:
```terminal
{"object_type":"asset","asset_id":"asset1","owner_org":"Org1MSP","public_description":"This asset is for sale"}
```

### [Operate from the Org2 terminal](https://hyperledger-fabric.readthedocs.io/en/release-2.3/secured_asset_transfer/secured_private_asset_transfer_tutorial.html#operate-from-the-org2-terminal)

Use the smart contract query the public asset data from the Org2 terminal:
```bash
peer chaincode query -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile ${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem -C mychannel -n secured -c '{"function":"ReadAsset","Args":["asset1"]}'
```

The result will be:
```terminal
{"objectType":"asset","assetID":"asset1","ownerOrg":"Org1MSP","publicDescription":"This asset is for sale"}
```

Try to change the public description as Org2:
```bash
peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile ${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem -C mychannel -n secured -c '{"function":"ChangePublicDescription","Args":["asset1","the worst asset"]}'
```

The smart contract will return **error**:
```terminal
Error: endorsement failure during invoke. response: status:500 message:"a client from Org2MSP cannot update the description of a asset owned by Org1MSP"
```

## [Agree to sell the asset](https://hyperledger-fabric.readthedocs.io/en/release-2.3/secured_asset_transfer/secured_private_asset_transfer_tutorial.html#agree-to-sell-the-asset)

### [Agree to sell as Org1](https://hyperledger-fabric.readthedocs.io/en/release-2.3/secured_asset_transfer/secured_private_asset_transfer_tutorial.html#agree-to-sell-as-org1)

`Org1` will agree to set the asset price as 110 dollars. The `trade_id` is used as `salt` to prevent a channel member that is not a buyer or a seller from guessing the price. This value needs to be passed out of band, through email or other communication, between the buyer and the seller. The buyer and the seller can also add `salt` to the asset key to prevent other members of the channel from guessing which asset is for sale.
```bash
export ASSET_PRICE=$(echo -n '{"asset_id":"asset1","trade_id":"109f4b3c50d7b0df729d299bc6f8e9ef9066971f","price":110}' | base64 -w 0)
peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile ${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem -C mychannel -n secured -c '{"function":"AgreeToSell","Args":["asset1"]}' --transient '{"asset_price":"'$ASSET_PRICE'"}'
```
The result will show:
```terminal
[chaincodeCmd] chaincodeInvokeOrQuery -> INFO 001 Chaincode invoke successful. result: status:200
```
Query the Org1 private data collection to read the agreed to selling price:
```bash
peer chaincode query -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile ${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem -C mychannel -n secured -c '{"function":"GetAssetSalesPrice","Args":["asset1"]}'
```
And the result will be:
```terminal
{"asset_id":"asset1","trade_id":"109f4b3c50d7b0df729d299bc6f8e9ef9066971f","price":110}
```

### [Agree to buy as Org2](https://hyperledger-fabric.readthedocs.io/en/release-2.3/secured_asset_transfer/secured_private_asset_transfer_tutorial.html#agree-to-buy-as-org2)
Run the following command in Org2 terminal to verify the asset properties. The asset properties and salt would be passed out of band, through email or other communication, between the buyer and seller.
```bash
export ASSET_PROPERTIES=$(echo -n '{"object_type":"asset_properties","asset_id":"asset1","color":"blue","size":35,"salt":"a94a8fe5ccb19ba61c4c0873d391e987982fbbd3"}' | base64 -w 0)
peer chaincode query -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile ${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem -C mychannel -n secured -c '{"function":"VerifyAssetProperties","Args":["asset1"]}' --transient '{"asset_properties":"'$ASSET_PROPERTIES'"}'
```

It should return `true`. Then try to agree to buy `asset1` for 100 dollars with the same trade_id as Org1.
```bash
export ASSET_PRICE=$(echo -n '{"asset_id":"asset1","trade_id":"109f4b3c50d7b0df729d299bc6f8e9ef9066971f","price":100}' | base64 -w 0)
peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile ${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem -C mychannel -n secured -c '{"function":"AgreeToBuy","Args":["asset1"]}' --transient '{"asset_price":"'$ASSET_PRICE'"}'
```

Read the agreed purchase price from the Org2 implicit data collection:
```bash
peer chaincode query -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile ${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem -C mychannel -n secured -c '{"function":"GetAssetBidPrice","Args":["asset1"]}'
```

## [Transfer the asset from Org1 to Org2](https://hyperledger-fabric.readthedocs.io/en/release-2.3/secured_asset_transfer/secured_private_asset_transfer_tutorial.html#transfer-the-asset-from-org1-to-org2)
The private asset transfer function in the smart contract uses the hash on the ledger to check that both organizations have agreed to the same price. The function will also use the hash of the private asset details to check that the asset that is transferred is the same asset that Org1 owns.

### [Transfer the asset as Org1](https://hyperledger-fabric.readthedocs.io/en/release-2.3/secured_asset_transfer/secured_private_asset_transfer_tutorial.html#transfer-the-asset-as-org1)
The owner of the asset needs to initiate the transfer from `Org1` terminal. The command below uses the `--peerAddresses` flag to target the peers of both `Org1` and `Org2`. Both organizations need to endorse the transfer. The asset properties and price are passed in the transfer request as transient properties and will be checked against the on-chain hashes by both endorsers.
```bash
peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile ${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem -C mychannel -n secured -c '{"function":"TransferAsset","Args":["asset1","Org2MSP"]}' --peerAddresses localhost:7051 --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt --peerAddresses localhost:9051 --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt --transient '{"asset_properties":"'$ASSET_PROPERTIES'","asset_price":"'$ASSET_PRICE'"}' 
```
Because there are not the same price, the transfer cannot be completed:
```terminal
Error: endorsement failure during invoke. response: status:500 message:"failed transfer verification: hash 0fc413250501855af7c9896af00993b973510995fb10d56cddbb85ca47bd5dba for passed price JSON {\"asset_id\":\"asset1\",\"trade_id\":\"109f4b3c50d7b0df729d299bc6f8e9ef9066971f\",\"price\":110} does not match on-chain hash 84b0d57eaa5c77076483ae8f482c96a64912c47df5541451e94fb7698bf37ee9, buyer hasn't agreed to the passed trade id and price"
```
Drops the price of the asset to 100:
```bash
export ASSET_PRICE=$(echo -n '{"asset_id":"asset1","trade_id":"109f4b3c50d7b0df729d299bc6f8e9ef9066971f","price":100}' | base64 -w 0)
peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile ${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem -C mychannel -n secured -c '{"function":"AgreeToSell","Args":["asset1"]}' --transient '{"asset_price":"'$ASSET_PRICE'"}'
```
The result should be:
```terminal
[chaincodeCmd] chaincodeInvokeOrQuery -> INFO 001 Chaincode invoke successful. result: status:200
```
Then try to transfer the asset to Org2 againg.
```bash
peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile ${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem -C mychannel -n secured -c '{"function":"TransferAsset","Args":["asset1","Org2MSP"]}' --peerAddresses localhost:7051 --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt --peerAddresses localhost:9051 --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt --transient '{"asset_properties":"'$ASSET_PROPERTIES'","asset_price":"'$ASSET_PRICE'"}' 
```
The result should be:
```terminal
[chaincodeCmd] chaincodeInvokeOrQuery -> INFO 001 Chaincode invoke successful. result: status:200
```
Query the asset ownership record to verify that the transfer was successful
```bash
peer chaincode query -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile ${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem -C mychannel -n secured -c '{"function":"ReadAsset","Args":["asset1"]}'
```
And the owner should be changed to `Org2` as:
```terminal
{"objectType":"asset","assetID":"asset1","ownerOrg":"Org2MSP","publicDescription":"This asset is for sale"}
```
### [Update the asset description as Org2](https://hyperledger-fabric.readthedocs.io/en/release-2.3/secured_asset_transfer/secured_private_asset_transfer_tutorial.html#update-the-asset-description-as-org2)

Read the asset details from the Org2 implicit data collection:
```bash
peer chaincode query -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile ${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem -C mychannel -n secured -c '{"function":"GetAssetPrivateProperties","Args":["asset1"]}'
```
Then the detail will be shown as:
```terminal
{"object_type":"asset_properties","asset_id":"asset1","color":"blue","size":35,"salt":"a94a8fe5ccb19ba61c4c0873d391e987982fbbd3"}
```
Try to update the asset public description:
```bash
peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile ${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem -C mychannel -n secured -c '{"function":"ChangePublicDescription","Args":["asset1","This asset is not for sale"]}'
```
The result should be:
```terminal
[chaincodeCmd] chaincodeInvokeOrQuery -> INFO 001 Chaincode invoke successful. result: status:200
```
Query the ledger to verify that the asset is no longer for sale:
```bash
peer chaincode query -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile ${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem -C mychannel -n secured -c '{"function":"ReadAsset","Args":["asset1"]}'
```
And the description will be changed to:
```terminal
{"objectType":"asset","assetID":"asset1","ownerOrg":"Org2MSP","publicDescription":"This asset is not for sale"}
```

## [Clean up](https://hyperledger-fabric.readthedocs.io/en/release-2.3/secured_asset_transfer/secured_private_asset_transfer_tutorial.html#clean-up)
```bash
./network.sh down
```
