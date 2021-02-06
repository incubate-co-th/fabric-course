# Join peers to the channel
[![Open this project in Cloud
Shell](http://gstatic.com/cloudssh/images/open-btn.png)](https://console.cloud.google.com/cloudshell/open?git_repo=https://github.com/incubate-co-th/fabric-course.git&page=editor&tutorial=join-peer.md)

After create channel and join orderer into the channel, the peer can be joined into the channel.

In Hyperledger Fabric, the tool [peer](https://hyperledger-fabric.readthedocs.io/en/release-2.3/commands/peercommand.html) are used to run peer node and set peer.

This tutorial adapt from [Create a channel without a system channel](https://hyperledger-fabric.readthedocs.io/en/release-2.3/create_channel/create_channel_participation.html#set-up-the-configtxgen-tool) in Hyperledger Fabric document.

## Before you begin

Please follow steps in the tutorial by run the following command to download `fabric-samples` folder form github:
```bash
teachme prerequisites.md
```

Start test network, create a genesis block and add orderer into the channel using the tutorial:
```bash
teachme first-orderer.md
```

## Add peer0 of Org1


```bash
CORE_PEER_TLS_ENABLED=true CORE_PEER_LOCALMSPID=Org1MSP CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp CORE_PEER_ADDRESS=localhost:7051 FABRIC_CFG_PATH=${PWD}/../config/ peer channel join -b ./channel-artifacts/mychannel.block
```

## Add peer0 of Org2
```bash
CORE_PEER_TLS_ENABLED=true CORE_PEER_LOCALMSPID=Org2MSP CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp CORE_PEER_ADDRESS=localhost:9051 FABRIC_CFG_PATH=${PWD}/../config/ peer channel join -b ./channel-artifacts/mychannel.block
```

## Set AnchorPeer
```bash
docker exec cli ./scripts/setAnchorPeer.sh 1 mychannel
docker exec cli ./scripts/setAnchorPeer.sh 2 mychannel
```

## Test with deployment
```bash
./network.sh deployCC -ccn basic -ccp ../asset-transfer-basic/chaincode-javascript -ccl javascript
```
