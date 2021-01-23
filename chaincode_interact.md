# Chaincode Deployment and Interaction
[![Open this project in Cloud
Shell](http://gstatic.com/cloudssh/images/open-btn.png)](https://console.cloud.google.com/cloudshell/open?git_repo=https://github.com/incubate-co-th/fabric-course.git&page=editor&tutorial=chaincode_interact.md)

Channels are a private layer of communication between specific network members.

This tutorial follow [Starting a chaincode on the channel](https://hyperledger-fabric.readthedocs.io/en/release-2.3/test_network.html#starting-a-chaincode-on-the-channel) and [Interacting with the network](https://hyperledger-fabric.readthedocs.io/en/release-2.3/test_network.html#interacting-with-the-network) in Hyperledger Fabric document.

We will create 3 channels on the test network that we create on <walkthrough-tutorial-card url="create_channel.md" label="prerequisites">`create_channel.md`</walkthrough-tutorial-card>.

## Before you begin

If the test network does not be started, please follow steps in the tutorial by run the following command:
```bash
teachme create_channel.md
```

## Change directory

You can find the scripts to create the channels in the test-network directory of the fabric-samples repository. Navigate to the test network directory by using the following command:
```bash
cd fabric-samples/test-network
```

## Starting a chaincode on the channel
After you have used the network.sh to create a channel, you can start a chaincode on the channel using the following command:
```bash
./network.sh deployCC -ccl javascript
```

The deployCC subcommand will install the **asset-transfer (basic)** chaincode on `peer0.org1.example.com` and `peer0.org2.example.com` and then deploy the chaincode on the channel specified using the channel flag (or `mychannel` if no channel is specified). If you are deploying a chaincode for the first time, the script will install the chaincode dependencies. By default, The script installs the Go version of the asset-transfer (basic) chaincode. However, you can use the language flag, `-l`, to install the typescript or javascript versions of the chaincode. You can find the asset-transfer (basic) chaincode in the `asset-transfer-basic` folder of the fabric-samples directory. This folder contains sample chaincode that are provided as examples and used by tutorials to highlight Fabric features.

## Interacting with the network
We will:
1. Set environment variables
2. Initial the Ledger
3. Query all states in ledger
4. Update the states in ledger
5. Confirm the data in another peer
6. Bring down the network


## Set environment variables
Use the following command to add those binaries to your CLI Path:

```bash
export PATH=${PWD}/../bin:$PATH
```

You also need to set the FABRIC_CFG_PATH to point to the core.yaml file in the fabric-samples repository:

```bash
export FABRIC_CFG_PATH=$PWD/../config/
```

You can now set the environment variables that allow you to operate the peer CLI as Org1:

```bash
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID="Org1MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
export CORE_PEER_ADDRESS=localhost:7051
```

The CORE_PEER_TLS_ROOTCERT_FILE and CORE_PEER_MSPCONFIGPATH environment variables point to the Org1 crypto material in the organizations folder.

If you used ./network.sh deployCC to install and start the asset-transfer (basic) chaincode, you can invoke the InitLedger function of the (Go) chaincode to put an initial list of assets on the ledger (if using typescript or javascript ./network.sh deployCC -l javascript for example, you will invoke the InitLedger function of the respective chaincodes).

## Initial the Ledger

Run the following command to initialize the ledger with assets:

```bash
peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile ${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem -C mychannel -n basic --peerAddresses localhost:7051 --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt --peerAddresses localhost:9051 --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt -c '{"function":"InitLedger","Args":[]}'
```

If successful, you should see similar output to below:

```
-> INFO 001 Chaincode invoke successful. result: status:200
```

## Query all states in ledger

You can now query the ledger from your CLI. Run the following command to get the list of assets that were added to your channel ledger:

```bash
peer chaincode query -C mychannel -n basic -c '{"Args":["GetAllAssets"]}'
```
If successful, you should see the following output:

```
[
  {"ID": "asset1", "color": "blue", "size": 5, "owner": "Tomoko", "appraisedValue": 300},
  {"ID": "asset2", "color": "red", "size": 5, "owner": "Brad", "appraisedValue": 400},
  {"ID": "asset3", "color": "green", "size": 10, "owner": "Jin Soo", "appraisedValue": 500},
  {"ID": "asset4", "color": "yellow", "size": 10, "owner": "Max", "appraisedValue": 600},
  {"ID": "asset5", "color": "black", "size": 15, "owner": "Adriana", "appraisedValue": 700},
  {"ID": "asset6", "color": "white", "size": 15, "owner": "Michel", "appraisedValue": 800}
]
```

## Update the states in ledger

Chaincodes are invoked when a network member wants to transfer or change an asset on the ledger. Use the following command to change the owner of an asset on the ledger by invoking the asset-transfer (basic) chaincode:

```bash
peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile ${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem -C mychannel -n basic --peerAddresses localhost:7051 --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt --peerAddresses localhost:9051 --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt -c '{"function":"TransferAsset","Args":["asset6","Christopher"]}'
```

If the command is successful, you should see the following response:

```
2019-12-04 17:38:21.048 EST [chaincodeCmd] chaincodeInvokeOrQuery -> INFO 001 Chaincode invoke successful. result: status:200
```

## Confirm the data in another peer

Because the endorsement policy for the asset-transfer (basic) chaincode requires the transaction to be signed by Org1 and Org2, the chaincode invoke command needs to target both peer0.org1.example.com and peer0.org2.example.com using the --peerAddresses flag. Because TLS is enabled for the network, the command also needs to reference the TLS certificate for each peer using the --tlsRootCertFiles flag.

After we invoke the chaincode, we can use another query to see how the invoke changed the assets on the blockchain ledger. Since we already queried the Org1 peer, we can take this opportunity to query the chaincode running on the Org2 peer. Set the following environment variables to operate as Org2:

```bash
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID="Org2MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp
export CORE_PEER_ADDRESS=localhost:9051
```

You can now query the asset-transfer (basic) chaincode running on peer0.org2.example.com:

```bash
peer chaincode query -C mychannel -n basic -c '{"Args":["ReadAsset","asset6"]}'
```
The result will show that "asset6" was transferred to Christopher:

```
{"ID":"asset6","color":"white","size":15,"owner":"Christopher","appraisedValue":800}
```

## Bring down the network
When you are finished using the test network, you can bring down the network with the following command:

```bash
./network.sh down
```

The command will stop and remove the node and chaincode containers, delete the organization crypto material, and remove the chaincode images from your Docker Registry. The command also removes the channel artifacts and docker volumes from previous runs, allowing you to run ./network.sh up again if you encountered any problems.
