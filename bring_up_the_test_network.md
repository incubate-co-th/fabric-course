# Bring up the test network

[![Open this project in Cloud
Shell](http://gstatic.com/cloudssh/images/open-btn.png)](https://console.cloud.google.com/cloudshell/open?git_repo=https://github.com/incubate-co-th/fabric-course.git&page=editor&tutorial=bring_up_the_test_network.md)

This tutorial follow https://hyperledger-fabric.readthedocs.io/en/release-2.3/test_network.html

## Before you begin

Please finish all steps in <walkthrough-tutorial-card url="prerequisites.md" label="prerequisites">`prerequisites.md`</walkthrough-tutorial-card> by click the following button and new cloud shell will be opened.

[![Open this project in Cloud
Shell](http://gstatic.com/cloudssh/images/open-btn.png)](https://console.cloud.google.com/cloudshell/open?git_repo=https://github.com/incubate-co-th/fabric-course.git&page=editor&tutorial=prerequisites.md)

## Bring up the test network
4 steps to bring up the test network

1. Change directory
2. Confirm the shell script
3. Remove all containers or artifacts
4. Bring up the network

## Change directory

You can find the scripts to bring up the network in the test-network directory of the fabric-samples repository. Navigate to the test network directory by using the following command:
```bash
cd fabric-samples/test-network
```

## Confirm the shell script
In this directory, you can find an annotated script, network.sh, that stands up a Fabric network using the Docker images on your local machine. You can run following command print the script help text:
```bash
 ./network.sh -h 
```

## Remove all containers or artifacts
From inside the test-network directory, run the following command to remove any containers or artifacts from any previous runs:
```bash
./network.sh down
```

## Bring up the network
You can then bring up the network by issuing the following command. You will experience problems if you try to run the script from another directory:
```bash
./network.sh up -i 2.3.0
```

## Confirm the result
Find the information of 3 containers
- image
- command
- ports
- names

and answer to the assignment.

You can confirm the running containers by using following command:

```bash
docker ps -a
```
