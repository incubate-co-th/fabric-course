# Running chaincode in development mode

[![Open this project in Cloud
Shell](http://gstatic.com/cloudssh/images/open-btn.png)](https://console.cloud.google.com/cloudshell/open?git_repo=https://github.com/incubate-co-th/fabric-course.git&page=editor&tutorial=dev_mode.md)

Channels are a private layer of communication between specific network members.

This tutorial adapt from [Running chaincode in development mode](https://hyperledger-fabric.readthedocs.io/en/release-2.3/peer-chaincode-devmode.html) in Hyperledger Fabric document.

## Before you begin

Please follow steps in the tutorial by run the following command:
```bash
teachme prerequisites.md
```

## Set up environment

### Get configuration from github

```bash
git clone https://github.com/hyperledger/fabric.git
mkdir dev
cp -R fabric/sampleconfig dev/
cd dev
```

The `yaml` files and data in `msp` from `sampleconfig` will be used.

### Pull the fabric-tools docker image

```bash
docker pull hyperledger/fabric-tools:2.3.0
docker pull hyperledger/fabric-orderer:2.3.0
docker pull hyperledger/fabric-peer:2.3.0
```

There are these tools in `hyperledger/fabric-tools:2.3.0` docker image:
- configtxgen
- configtxlator
- cryptogen
- discover
- idemixgen
- peer


### Remove prevoius setting
```bash
rm -f sampleconfig/genesisblock
rm -f sampleconfig/ch1*
docker network rm dev-net
```

### Create docker network
```bash
docker network create dev-net
```

### Change `configtx.yaml` in `sampleconfig` folder
Update the name of orderer and peer by:
- Change value of `Organizations.&SampleOrg.OrdererEndpoints` from `"127.0.0.1:7050"` to `"fabric-orderer:7050"`
- Change value of `Organizations.&SampleOrg.AnchorPeers.Host` from `127.0.0.1` to `fabric-peer`

## Generate the genesis block
Use docker to generate the genesis block
```bash
docker run -ti --rm --network dev-net --name fabric-tools-genesis -v ${PWD}/sampleconfig:/home/config -e CORE_VM_ENDPOINT=unix:///host/var/run/docker.sock hyperledger/fabric-tools:2.3.0 configtxgen -profile SampleDevModeSolo -channelID syschannel -outputBlock genesisblock -configPath /home/config -outputBlock /home/config/genesisblock
```

where:
-profile - Is the name of the profile in configtx.yaml that will be used to create the channel.
-outputBlock - Is the location of where to store the generated configuration block file.
-channelID - Is the name of the channel being created. Channel names must be all lower case, less than 250 characters long and match the regular expression [a-z][a-z0-9.-]*. The command uses the -profile flag to reference the SampleAppGenesisEtcdRaft: profile from configtx.yaml.
-configPath - Is the path containing the configuration to use (if set)

The result should be similar to:
```terminal
[common.tools.configtxgen] doOutputBlock -> INFO 005 Writing genesis block
```
## [Start the orderer](https://hyperledger-fabric.readthedocs.io/en/release-2.3/peer-chaincode-devmode.html#start-the-orderer)
**Open new terminal and change directory to `dev`.** and use docker run command to start an orderer container
```bash
docker run -it --rm --network dev-net -v ${PWD}/sampleconfig:/home/config -e FABRIC_CFG_PATH=/home/config -e ORDERER_GENERAL_LISTENADDRESS=0.0.0.0 -e ORDERER_GENERAL_GENESISPROFILE=SampleDevModeSolo --name fabric-orderer -p 7050:7050 hyperledger/fabric-orderer:2.3.0
```

The result should be similar to:
```terminal
Main -> INFO 00c Beginning to serve requests
```

## [Start the peer in DevMode](https://hyperledger-fabric.readthedocs.io/en/release-2.3/peer-chaincode-devmode.html#start-the-peer-in-devmode)
**Open new terminal and change directory to `dev`.** and use docker run command to start an peer container
```bash
docker run -it --rm --network dev-net -v ${PWD}/sampleconfig:/home/config -e FABRIC_CFG_PATH=/home/config -e CORE_VM_ENDPOINT=unix:///host/var/run/docker.sock --name fabric-peer -e FABRIC_LOGGING_SPEC=chaincode=debug -e CORE_PEER_CHAINCODELISTENADDRESS=0.0.0.0:7052 -p 7052:7052 -p 7051:7051 -p 7053:7053 hyperledger/fabric-peer:2.3.0 peer node start --peer-chaincodedev=true
```
The result should be similar to:
```terminal
[nodeCmd] serve -> INFO 00e Running in chaincode development mode
```
## [Create channel and join peer](https://hyperledger-fabric.readthedocs.io/en/release-2.3/peer-chaincode-devmode.html#create-channel-and-join-peer)
At the first terminal, use the docker run command to create channel:
```bash
docker run -ti --rm --network dev-net --name fabric-tools-channel -v ${PWD}/sampleconfig:/home/config -e CORE_VM_ENDPOINT=unix:///host/var/run/docker.sock hyperledger/fabric-tools:2.3.0 configtxgen -channelID ch1 -outputCreateChannelTx /home/config/ch1.tx -profile SampleSingleMSPChannel -configPath /home/config
```

And join the peer to the channel.
```bash
docker run -ti --rm --network dev-net --name fabric-tools-peer -v ${PWD}/sampleconfig:/home/config -e CORE_VM_ENDPOINT=unix:///host/var/run/docker.sock -e FABRIC_CFG_PATH=/home/config hyperledger/fabric-tools:2.3.0 peer channel create -o fabric-orderer:7050 -c ch1 -f /home/config/ch1.tx --outputBlock /home/config/ch1.block
```

The result should be similar to:
```terminal
[cli.common] readBlock -> INFO 002 Received block: 0
```
Then join the peer to the channel by running the following command:
```bash
docker exec fabric-peer peer channel join -o fabric-orderer:7050 -b /home/config/ch1.block
```

The result should be similar to:
```terminal
[channelCmd] executeJoin -> INFO 002 Successfully submitted proposal to join channel
```

## [Build the chaincode](https://hyperledger-fabric.readthedocs.io/en/release-2.3/peer-chaincode-devmode.html#build-the-chaincode)
Copy javascript chaincode from `fabric-samples` and build:  
```bash
cp -r ../fabric-samples/asset-transfer-basic/chaincode-javascript .
cd chaincode-javascript/
npm install
```

## [Start the chaincode](https://hyperledger-fabric.readthedocs.io/en/release-2.3/peer-chaincode-devmode.html#start-the-chaincode)
Run the chaincode and connect to the peer:
```bash
CORE_CHAINCODE_LOGLEVEL=debug CORE_PEER_TLS_ENABLED=false CORE_CHAINCODE_ID_NAME="mycc:1.0" npm run start -- --peer.address 127.0.0.1:7052
```
Check both orderer and peer terminals

## [Approve and commit the chaincode definition](https://hyperledger-fabric.readthedocs.io/en/release-2.3/peer-chaincode-devmode.html#approve-and-commit-the-chaincode-definition)
Run the following Fabric chaincode lifecycle commands to approve and commit the chaincode definition to the channel:
```bash
docker exec fabric-peer peer lifecycle chaincode approveformyorg  -o fabric-orderer:7050 --channelID ch1 --name mycc --version 1.0 --sequence 1 --init-required --signature-policy "OR ('SampleOrg.member')" --package-id mycc:1.0
docker exec fabric-peer peer lifecycle chaincode checkcommitreadiness -o fabric-orderer:7050 --channelID ch1 --name mycc --version 1.0 --sequence 1 --init-required --signature-policy "OR ('SampleOrg.member')"
docker exec fabric-peer peer lifecycle chaincode commit -o fabric-orderer:7050 --channelID ch1 --name mycc --version 1.0 --sequence 1 --init-required --signature-policy "OR ('SampleOrg.member')" --peerAddresses fabric-peer:7051
```

Check both orderer and peer terminals
## [Next steps](https://hyperledger-fabric.readthedocs.io/en/release-2.3/peer-chaincode-devmode.html#next-steps)

Try to run these commands:

```bash
docker run -ti --rm --network dev-net --name fabric-tools-peer -v ${PWD}/sampleconfig:/home/config -e CORE_VM_ENDPOINT=unix:///host/var/run/docker.sock -e FABRIC_CFG_PATH=/home/config -e CORE_PEER_ADDRESS=fabric-peer:7051 hyperledger/fabric-tools:2.3.0 peer chaincode invoke -o fabric-orderer:7050 -C ch1 -n mycc -c '{"function":"InitLedger","Args":[]}'  --isInit
```

```bash
docker run -ti --rm --network dev-net --name fabric-tools-peer -v ${PWD}/sampleconfig:/home/config -e CORE_VM_ENDPOINT=unix:///host/var/run/docker.sock -e FABRIC_CFG_PATH=/home/config -e CORE_PEER_ADDRESS=fabric-peer:7051 hyperledger/fabric-tools:2.3.0 peer chaincode invoke -o fabric-orderer:7050 -C ch1 -n mycc -c '{"Args":["GetAllAssets"]}'
```

```bash
docker run -ti --rm --network dev-net --name fabric-tools-peer -v ${PWD}/sampleconfig:/home/config -e CORE_VM_ENDPOINT=unix:///host/var/run/docker.sock -e FABRIC_CFG_PATH=/home/config -e CORE_PEER_ADDRESS=fabric-peer:7051 hyperledger/fabric-tools:2.3.0 peer chaincode invoke -o fabric-orderer:7050 -C ch1 -n mycc -c '{"function":"CreateAsset","Args":["asset8","blue","16","Kelley","750"]}'
```

```bash
docker run -ti --rm --network dev-net --name fabric-tools-peer -v ${PWD}/sampleconfig:/home/config -e CORE_VM_ENDPOINT=unix:///host/var/run/docker.sock -e FABRIC_CFG_PATH=/home/config -e CORE_PEER_ADDRESS=fabric-peer:7051 hyperledger/fabric-tools:2.3.0 peer chaincode invoke -o fabric-orderer:7050 -C ch1 -n mycc -c '{"function":"CreateAsset","Args":["asset7","gold","50","Suchit","1000"]}'
```
The result should be similar to the test-network.

Now, you can run command in `Start the chaincode` step without following the lifecycle (in `Approve and commit the chaincode definition`) for update the chaincode.
