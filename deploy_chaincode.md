# Chaincode Deployment and Interaction
[![Open this project in Cloud
Shell](http://gstatic.com/cloudssh/images/open-btn.png)](https://console.cloud.google.com/cloudshell/open?git_repo=https://github.com/incubate-co-th/fabric-course.git&page=editor&tutorial=deploy_chaincode.md)

Channels are a private layer of communication between specific network members.

This tutorial follow [Deploying a smart contract to a channel](https://hyperledger-fabric.readthedocs.io/en/release-2.3/deploy_chaincode.html) in Hyperledger Fabric document.

## Before you begin

Please follow steps in the tutorial by run the following command:
```bash
teachme prerequisites.md
```

## Change directory

You can find the scripts to create the channels in the test-network directory of the fabric-samples repository. Navigate to the test network directory by using the following command:
```bash
cd fabric-samples/test-network
```

## Starting the network

Kill any active or stale docker containers and remove previously generated artifacts
```bash
./network.sh down
```

Then use the following command to start the test network
```bash
./network.sh up createChannel -i 2.3.0
```

## [Setup Logspout (optional)](https://hyperledger-fabric.readthedocs.io/en/release-2.3/deploy_chaincode.html#setup-logspout-optional)

[Logspout](https://logdna.com/blog/what-is-logspout/) is an open source log router designed specifically for Docker container logs. 

In new tab, create logspout containner version 3.2.13

```bash
docker run -d --name="logspout" --volume=/var/run/docker.sock:/var/run/docker.sock --publish=127.0.0.1:8000:80 --network net_test gliderlabs/logspout:v3.2.13
```

If there are any problem with docker, try to delete logspout by the follow command:
```bash
docker rm $(docker stop logspout)
```

Then add the monitor to the command prompt by:
```bash
curl http://127.0.0.1:8000/logs
```

## [Package the smart contract (Typescript)](https://hyperledger-fabric.readthedocs.io/en/release-2.3/deploy_chaincode.html#typescript)

### Change directory to the code folder

```bash
cd ../asset-transfer-basic/chaincode-typescript
```

### Install dependencies
```bash
npm install
```

### Compile typescript into javascript
```bash
npm run build
```

### Change directory back to the test-network script
```bash
cd ../../test-network
```

### Confirm the setting to use peer command
```bash
peer version
```

If there is a `command not found` error add the following environment variable setting:
```bash
export PATH=${PWD}/../bin:$PATH
export FABRIC_CFG_PATH=$PWD/../config/
```

And test the version of peer command again.

### Create the chaincode package using the [peer lifecycle chaincode package](https://hyperledger-fabric.readthedocs.io/en/release-2.3/commands/peerlifecycle.html#peer-lifecycle-chaincode-package) command

```bash
peer lifecycle chaincode package basic.tar.gz --path ../asset-transfer-basic/chaincode-typescript/ --lang node --label basic_1.0
```

The `basic.tar.gz` file will be created.

## [Install the chaincode package](https://hyperledger-fabric.readthedocs.io/en/release-2.3/deploy_chaincode.html#install-the-chaincode-package)

The chaincode needs to be installed on every peer that will endorse a transaction. Because we are going to set the endorsement policy to require endorsements from both Org1 and Org2, we need to install the chaincode on the peers operated by both organizations.

### Install the chaincode into Org1
Set the following environment variables to operate the peer CLI as the Org1 admin user.

```bash
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID="Org1MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
export CORE_PEER_ADDRESS=localhost:7051
```

Issue the [peer lifecycle chaincode install](https://hyperledger-fabric.readthedocs.io/en/release-2.3/commands/peerlifecycle.html#peer-lifecycle-chaincode-install) command to install the chaincode on the peer.

```bash
peer lifecycle chaincode install basic.tar.gz
```

### Install the chaincode into Org2

Set the following environment variables to operate as the Org2 admin and target target the Org2 peer

```bash
export CORE_PEER_LOCALMSPID="Org2MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp
export CORE_PEER_ADDRESS=localhost:9051
```

Issue the following command to install the chaincode

```bash
peer lifecycle chaincode install basic.tar.gz
```

## [Approve a chaincode definition](https://hyperledger-fabric.readthedocs.io/en/release-2.3/deploy_chaincode.html#approve-a-chaincode-definition)

### Query installed chaincode from peer

Using the [peer lifecycle chaincode queryinstalled](https://hyperledger-fabric.readthedocs.io/en/release-2.3/commands/peerlifecycle.html#peer-lifecycle-chaincode-queryinstalled) command to query your peer:
```bash
peer lifecycle chaincode queryinstalled
```

Save it as an environment variable

```bash
export CC_PACKAGE_ID=$(peer lifecycle chaincode queryinstalled | sed 1d | cut -d' ' -f3 | cut -d',' -f1)
```

Approve the chaincode definition using the [peer lifecycle chaincode approveformyorg](https://hyperledger-fabric.readthedocs.io/en/release-2.3/commands/peerlifecycle.html#peer-lifecycle-chaincode-approveformyorg) command:


### Approve the chaincode

Approve the chaincode definition using the [peer lifecycle chaincode approveformyorg](https://hyperledger-fabric.readthedocs.io/en/release-2.3/commands/peerlifecycle.html#peer-lifecycle-chaincode-approveformyorg) command

```bash
peer lifecycle chaincode approveformyorg -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --channelID mychannel --name basic --version 1.0 --package-id $CC_PACKAGE_ID --sequence 1 --tls --cafile ${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
```

### Approve the chaincode definition as Org1. 

Set the following environment variables to operate as the Org1 admin

```bash
export CORE_PEER_LOCALMSPID="Org1MSP"
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
export CORE_PEER_ADDRESS=localhost:7051
```

Approve the chaincode definition as Org1

```bash
peer lifecycle chaincode approveformyorg -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --channelID mychannel --name basic --version 1.0 --package-id $CC_PACKAGE_ID --sequence 1 --tls --cafile ${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
```

## [Committing the chaincode definition to the channel](https://hyperledger-fabric.readthedocs.io/en/release-2.3/deploy_chaincode.html#committing-the-chaincode-definition-to-the-channel)

Use the [peer lifecycle chaincode checkcommitreadiness](https://hyperledger-fabric.readthedocs.io/en/release-2.3/commands/peerlifecycle.html#peer-lifecycle-chaincode-checkcommitreadiness) command to check whether channel members have approved the same chaincode definition.

```bash
peer lifecycle chaincode checkcommitreadiness --channelID mychannel --name basic --version 1.0 --sequence 1 --tls --cafile ${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem --output json
```

Use the [peer lifecycle chaincode commit](https://hyperledger-fabric.readthedocs.io/en/release-2.3/commands/peerlifecycle.html#peer-lifecycle-chaincode-commit) command to commit the chaincode definition to the channel


```bash
peer lifecycle chaincode commit -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --channelID mychannel --name basic --version 1.0 --sequence 1 --tls --cafile ${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem --peerAddresses localhost:7051 --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt --peerAddresses localhost:9051 --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt
```

Use the [peer lifecycle chaincode querycommitted](https://hyperledger-fabric.readthedocs.io/en/release-2.3/commands/peerlifecycle.html#peer-lifecycle-chaincode-querycommitted) command to confirm that the chaincode definition has been committed to the channel


```bash
peer lifecycle chaincode querycommitted --channelID mychannel --name basic --cafile ${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
```

## [Invoking the chaincode](https://hyperledger-fabric.readthedocs.io/en/release-2.3/deploy_chaincode.html#invoking-the-chaincode)


```bash
peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile ${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem -C mychannel -n basic --peerAddresses localhost:7051 --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt --peerAddresses localhost:9051 --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt -c '{"function":"InitLedger","Args":[]}'
```

## [Upgrading a smart contract](https://hyperledger-fabric.readthedocs.io/en/release-2.3/deploy_chaincode.html#upgrading-a-smart-contract)

Change the version of code from Typescript to Javascript.

### Install dependencies

```bash
cd ../asset-transfer-basic/chaincode-javascript
npm install
cd ../../test-network
```

### Pack the chaincode

Create `basic_2.tar.gz` using [peer lifecycle chaincode package](https://hyperledger-fabric.readthedocs.io/en/release-2.3/commands/peerlifecycle.html#peer-lifecycle-chaincode-package) command

```bash
export PATH=${PWD}/../bin:$PATH
export FABRIC_CFG_PATH=$PWD/../config/
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
peer lifecycle chaincode package basic_2.tar.gz --path ../asset-transfer-basic/chaincode-javascript/ --lang node --label basic_2.0
```

### Install the chaincode to Org1

Set environment variables:
```bash
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID="Org1MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
export CORE_PEER_ADDRESS=localhost:7051
```

Install the net chaincode
```bash
peer lifecycle chaincode install basic_2.tar.gz
```

### Approve the chaincode
Check the Package ID
```bash
peer lifecycle chaincode queryinstalled
```

Set the environment variable for new version
```bash
export NEW_CC_PACKAGE_ID=$(peer lifecycle chaincode queryinstalled | sed '1,2d' | cut -d' ' -f3 | cut -d',' -f1)
```

Approve the chaincode in Org1
```bash
peer lifecycle chaincode approveformyorg -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --channelID mychannel --name basic --version 2.0 --package-id $NEW_CC_PACKAGE_ID --sequence 2 --tls --cafile ${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
```

### Install the chaincode to Org2

Set environment variables:
```bash
export CORE_PEER_LOCALMSPID="Org2MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp
export CORE_PEER_ADDRESS=localhost:9051
```

Install the net chaincode
```bash
peer lifecycle chaincode install basic_2.tar.gz
```

Approve the chaincode in Org2

```bash
peer lifecycle chaincode approveformyorg -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --channelID mychannel --name basic --version 2.0 --package-id $NEW_CC_PACKAGE_ID --sequence 2 --tls --cafile ${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
```

### Commit the chaincode definition

Check if the chaincode definition with sequence 2 is ready to be committed to the channel
```bash
peer lifecycle chaincode checkcommitreadiness --channelID mychannel --name basic --version 2.0 --sequence 2 --tls --cafile ${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem --output json
```

The chaincode will be upgraded on the channel after the new chaincode definition is committed. Until then, the previous chaincode will continue to run on the peers of both organizations. Org2 can use the following command to upgrade the chaincode
```bash
peer lifecycle chaincode commit -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --channelID mychannel --name basic --version 2.0 --sequence 2 --tls --cafile ${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem --peerAddresses localhost:7051 --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt --peerAddresses localhost:9051 --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt
```
### Confirm the new chaincode

Confirm the version of chaincode:
```bash
docker ps
```

Try to create new asset

```bash
peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile ${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem -C mychannel -n basic --peerAddresses localhost:7051 --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt --peerAddresses localhost:9051 --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt -c '{"function":"CreateAsset","Args":["asset8","blue","16","Kelley","750"]}'
```

And get all assets

```bash
peer chaincode query -C mychannel -n basic -c '{"Args":["GetAllAssets"]}'
```

## [Clean up](https://hyperledger-fabric.readthedocs.io/en/release-2.3/deploy_chaincode.html#clean-up)

```bash
docker rm $(docker stop logspout)
./network.sh down
```
