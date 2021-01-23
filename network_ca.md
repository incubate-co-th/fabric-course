# Bring up the network with Certificate Authorities
[![Open this project in Cloud
Shell](http://gstatic.com/cloudssh/images/open-btn.png)](https://console.cloud.google.com/cloudshell/open?git_repo=https://github.com/incubate-co-th/fabric-course.git&page=editor&tutorial=network_ca.md)

This tutorial follow [Bring up the network with Certificate Authorities](https://hyperledger-fabric.readthedocs.io/en/release-2.3/test_network.html#bring-up-the-network-with-certificate-authorities).

## Before you begin

Please finish 'prerequisites.md' by run the follow command:
```bash
teachme prerequisites.md
```

## Change Directory
You can find the scripts to create the channels in the test-network directory of the fabric-samples repository. Navigate to the test network directory by using the following command:
```bash
cd fabric-samples/test-network
```

## Bring up the network with Certificate Authorities

### Bring down the network
If you would like to bring up a network using Fabric CAs, first run the following command to bring down any running networks:
```bash
./network.sh down
```

### Bring up the network with CA
You can then bring up the network with the CA flag:
```bash
./network.sh up -i 2.3.0 -ca
```

After you issue the command, you can see the script bringing up three CAs, one for each organization in the network.
```
##########################################################
##### Generate certificates using Fabric CA's ############
##########################################################
Creating network "net_default" with the default driver
Creating ca_org2    ... done
Creating ca_org1    ... done
Creating ca_orderer ... done
```

## 
