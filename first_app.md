# Writing Your First Application
[![Open this project in Cloud
Shell](http://gstatic.com/cloudssh/images/open-btn.png)](https://console.cloud.google.com/cloudshell/open?git_repo=https://github.com/incubate-co-th/fabric-course.git&page=editor&tutorial=first_app.md)


This tutorial follow [Writing Your First Application](https://hyperledger-fabric.readthedocs.io/en/release-2.3/write_first_app.html).

## Before you begin

Please finish 'prerequisites.md' by run the follow command:
```bash
teachme prerequisites.md
```

## Launch the network

Navigate to the test-network subdirectory within your local clone of the fabric-samples repository.
```bash
cd fabric-samples/test-network
```

If you already have a test network running, bring it down to ensure the environment is clean.
```bash
./network.sh down
```

Launch the Fabric test network using the network.sh shell script.

```bash
./network.sh up createChannel -i 2.3.0 -c mychannel -ca
```

This command will deploy the Fabric test network with two peers, an ordering service, and three certificate authorities (Orderer, Org1, Org2). Instead of using the cryptogen tool, we bring up the test network using Certificate Authorities, hence the -ca flag. Additionally, the org admin user registration is bootstrapped when the Certificate Authority is started. In a later step, we will show how the sample application completes the admin enrollment.

## Deploy the chaincode

Next, let’s deploy the chaincode by calling the ./network.sh script with the chaincode name and language options.
```bash
./network.sh deployCC -ccn basic -ccp ../asset-transfer-basic/chaincode-javascript/ -ccl javascript
```
Note

Behind the scenes, this script uses the chaincode lifecycle to package, install, query installed chaincode, approve chaincode for both Org1 and Org2, and finally commit the chaincode.

If the chaincode is successfully deployed, the end of the output in your terminal should look similar to below:
```
Committed chaincode definition for chaincode 'basic' on channel 'mychannel':
Version: 1.0, Sequence: 1, Endorsement Plugin: escc, Validation Plugin: vscc, Approvals: [Org1MSP: true, Org2MSP: true]
===================== Query chaincode definition successful on peer0.org2 on channel 'mychannel' =====================

===================== Chaincode initialization is not required =====================
```

## Sample application
Next, let’s prepare the sample Asset Transfer Javascript application that will be used to interact with the deployed chaincode.

JavaScript application
Note that the sample application is also available in Go and Java at the links below:

Go application
Java application
Open a new terminal, and navigate to the application-javascript folder.

```bash
cd ../asset-transfer-basic/application-javascript
```
This directory contains sample programs that were developed using the Fabric SDK for Node.js. Run the following command to install the application dependencies. It may take up to a minute to complete:

```bash
npm install
```

This process is installing the key application dependencies defined in the application’s package.json. The most important of which is the fabric-network Node.js module; it enables an application to use identities, wallets, and gateways to connect to channels, submit transactions, and wait for notifications. This tutorial also uses the fabric-ca-client module to enroll users with their respective certificate authorities, generating a valid identity which is then used by the fabric-network module to interact with the blockchain network.

Once npm install completes, everything is in place to run the application. Let’s take a look at the sample JavaScript application files we will be using in this tutorial. Run the following command to list the files in this directory:
```bash
ls
```
You should see the following:
```
app.js                  node_modules            package.json       package-lock.json
```
Note

The first part of the following section involves communication with the Certificate Authority. You may find it useful to stream the CA logs when running the upcoming programs by opening a new terminal shell and running `docker logs -f ca_org1`.

When we started the Fabric test network back in the first step, an admin user — literally called admin — was created as the registrar for the Certificate Authority (CA). Our first step is to generate the private key, public key, and X.509 certificate for admin by having the application call the enrollAdmin . This process uses a Certificate Signing Request (CSR) — the private and public key are first generated locally and the public key is then sent to the CA which returns an encoded certificate for use by the application. These credentials are then stored in the wallet, allowing us to act as an administrator for the CA.

Let’s run the application and then step through each of the interactions with the smart contract functions. From the asset-transfer-basic/application-javascript directory, run the following command:
```bash
node app.js
```

## Bring down the network

Bring down the network and change directory
```bash
cd ../../test-network
./network.sh down
cd ../..
```
