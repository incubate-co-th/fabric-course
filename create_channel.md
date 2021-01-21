# Chreate Channels
[![Open this project in Cloud
Shell](http://gstatic.com/cloudssh/images/open-btn.png)](https://console.cloud.google.com/cloudshell/open?git_repo=https://github.com/incubate-co-th/fabric-course.git&page=editor&tutorial=create_channel.md)

Channels are a private layer of communication between specific network members.

We will create 3 channels on the test network that we create on <walkthrough-tutorial-card url="bring_up_the_test_network.md" label="prerequisites">`bring_up_the_test_network.md`</walkthrough-tutorial-card>.

If the test network does not be started, please follow steps in the tutorial by run the following command:
```bash
teachme bring_up_the_test_network.md
```

This tutorial follow [Creating a channel](https://hyperledger-fabric.readthedocs.io/en/release-2.3/test_network.html#creating-a-channel) in Hyperledger Fabric document.

## Change directory

You can find the scripts to create the channels in the test-network directory of the fabric-samples repository. Navigate to the test network directory by using the following command:
```bash
cd fabric-samples/test-network
```

## Default channel

You can use the network.sh script to create a channel between Org1 and Org2 and join their peers to the channel. Run the following command to create a channel with the default name of mychannel:

```bash
./network.sh createChannel
```

If the command was successful, you can see the following message printed in your logs:

```
========= Channel successfully joined ===========
```

## Create new channel
You can also use the channel flag to create a channel with custom name. As an example, the following command would create a channel named channel1:

```bash
./network.sh createChannel -c channel1
```

## Create third channel
The channel flag also allows you to create multiple channels by specifying different channel names. After you create mychannel or channel1, you can use the command below to create a second channel named channel2:
```bash
./network.sh createChannel -c channel2
```

