# Genesis Block
[![Open this project in Cloud
Shell](http://gstatic.com/cloudssh/images/open-btn.png)](https://console.cloud.google.com/cloudshell/open?git_repo=https://github.com/incubate-co-th/fabric-course.git&page=editor&tutorial=genesis.md)

The genesis block are needed for blockchain and have to be created differently.

In Hyperledger Fabric, the tool [configtxgen](https://hyperledger-fabric.readthedocs.io/en/latest/commands/configtxgen.html) are used to create a genesis block.

This tutorial adapt from [Create a channel without a system channel](https://hyperledger-fabric.readthedocs.io/en/release-2.3/create_channel/create_channel_participation.html#set-up-the-configtxgen-tool) in Hyperledger Fabric document.

## Before you begin

Please follow steps in the tutorial by run the following command to download `fabric-samples` folder form github:
```bash
teachme prerequisites.md
```

## Set up environment

### Bring up the test network
```bash
cd fabric-samples/test-network
./network.sh up -i 2.3.0
```

## Create a genesis block for application channel 
```bash
FABRIC_CFG_PATH=${PWD}/configtx configtxgen -profile TwoOrgsApplicationGenesis -outputBlock ./channel-artifacts/mychannel.block -channelID mychannel
```

## Inspect a created genesis block
```bash
FABRIC_CFG_PATH=${PWD}/configtx configtxgen -inspectBlock ./channel-artifacts/mychannel.block | jq
```

