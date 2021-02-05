# Ordered
Fabric v2.3 introduces the capability to create a channel without requiring a system channel, removing an extra layer of administration from the process. We will create the cannel without a system channel.

[![Open this project in Cloud
Shell](http://gstatic.com/cloudssh/images/open-btn.png)](https://console.cloud.google.com/cloudshell/open?git_repo=https://github.com/incubate-co-th/fabric-course.git&page=editor&tutorial=orderer.md)

Channels are a private layer of communication between specific network members.

This tutorial adapt from [Running chaincode in development mode](https://hyperledger-fabric.readthedocs.io/en/release-2.3/peer-chaincode-devmode.html) in Hyperledger Fabric document.

## Before you begin

Please follow steps in the tutorial by run the following command to download `fabric-samples` folder form github:
```bash
teachme prerequisites.md
```

## Set up environment

### Pull the fabric-tools docker image
```bash
docker pull hyperledger/fabric-orderer:2.3.0
docker pull hyperledger/fabric-ca:1.4.9
```

## [Create certificates](https://hyperledger-fabric.readthedocs.io/en/release-2.3/deployorderer/ordererdeploy.html#certificates)

Generate the following sets of certificates:

- Orderer organization MSP
- Orderer TLS CA certificates
- Orderer local MSP (enrollment certificate and private key of the orderer)

And put in the folders as shown in [Folder structure](https://hyperledger-fabric.readthedocs.io/en/release-2.3/create_channel/create_channel_participation.html#folder-structure)

## TLS CA
Steps refer to tutorial on TLS CA, `tls-ca.md`:

1. Initialize the CA server

```bash
docker run --rm --name tls-ca.ordererOrg1.example.com -v ${PWD}/organizations/ordererOrganizations/tls-ca.ordererOrg1.example.com:/root/ca-server hyperledger/fabric-ca:1.4.9 fabric-ca-server init -b tls-admin:tls-adminpw -H /root/ca-server
```

2. Modify the CA server configuration

Edit the `fabric-ca-server-config.yaml` in `tls-ca.ordererOrg1.example.com` folder.
```bash
sudo chown -R $USER:$USER organizations
cloudshell edit organizations/ordererOrganizations/tls-ca.ordererOrg1.example.com/fabric-ca-server-config.yaml
```

or <walkthrough-editor-open-file filePath="organizations/ordererOrganizations/tls-ca.ordererOrg1.example.com/fabric-ca-server-config.yaml" text="Open config file"></walkthrough-editor-open-file>

with:

**`port`** - `7054`.

**`tls.enabled`** - `true`

**`ca.name`** - `tls-ca.ordererOrg1.example.com`

**`ca.cn`** - `tls-ca.ordererOrg1.example.com`

**`csr.hosts`** - Add `'*.ordererOrg1.example.com'`

**`signing.profiles.ca`** - Remove

Then save the file and go to next step.

3. Delete the CA server certificates

```bash
sudo rm organizations/ordererOrganizations/tls-ca.ordererOrg1.example.com/ca-cert.pem
sudo rm -rf organizations/ordererOrganizations/tls-ca.ordererOrg1.example.com/msp
```

4. Start the CA server

Run the command below to start CA in docker containner in new terminal:
```bash
docker run --rm -p 7054:7054 --name tls-ca.ordererOrg1.example.com -v ${PWD}/organizations/ordererOrganizations/tls-ca.ordererOrg1.example.com:/root/ca-server hyperledger/fabric-ca:1.4.9  fabric-ca-server start -b tls-admin:tls-adminpw -H /root/ca-server
```

5. Enroll bootstrap user with TLS CA

```bash
mkdir organizations/ordererOrganizations/tls-ca-client.ordererOrg1.example.com
mkdir organizations/ordererOrganizations/tls-ca-client.ordererOrg1.example.com/tls-ca
mkdir organizations/ordererOrganizations/tls-ca-client.ordererOrg1.example.com/tls-root-cert
cp organizations/ordererOrganizations/tls-ca.ordererOrg1.example.com/ca-cert.pem organizations/ordererOrganizations/tls-ca-client.ordererOrg1.example.com/tls-root-cert/tls-ca-cert.pem
docker run --rm --name tls-ca-client.ordererOrg1.example.com --link tls-ca.ordererOrg1.example.com:tls-ca.ordererOrg1.example.com -v ${PWD}/organizations/ordererOrganizations/tls-ca-client.ordererOrg1.example.com:/root/ca-client -e FABRIC_CA_CLIENT_HOME=/root/ca-client  hyperledger/fabric-ca:1.4.9 fabric-ca-client enroll -d -u https://tls-admin:tls-adminpw@tls-ca.ordererOrg1.example.com:7054 --tls.certfiles tls-root-cert/tls-ca-cert.pem --enrollment.profile tls --csr.hosts 'host1,*.ordererOrg1.example.com' --mspdir tls-ca/tlsadmin/msp
```

6. Register and enroll the organization CA bootstrap identity with the TLS CA

```bash
docker run --rm --name tls-ca-client.ordererOrg1.example.com --link tls-ca.ordererOrg1.example.com:tls-ca.ordererOrg1.example.com -v ${PWD}/organizations/ordererOrganizations/tls-ca-client.ordererOrg1.example.com:/root/ca-client -e FABRIC_CA_CLIENT_HOME=/root/ca-client  hyperledger/fabric-ca:1.4.9 fabric-ca-client register -d --id.name rcaadmin --id.secret rcaadminpw -u https://tls-ca.ordererOrg1.example.com:7054  --tls.certfiles tls-root-cert/tls-ca-cert.pem --mspdir tls-ca/tlsadmin/msp
docker run --rm --name tls-ca-client.ordererOrg1.example.com --link tls-ca.ordererOrg1.example.com:tls-ca.ordererOrg1.example.com -v ${PWD}/organizations/ordererOrganizations/tls-ca-client.ordererOrg1.example.com:/root/ca-client -e FABRIC_CA_CLIENT_HOME=/root/ca-client hyperledger/fabric-ca:1.4.9 fabric-ca-client enroll -d -u https://rcaadmin:rcaadminpw@tls-ca.ordererOrg1.example.com:7054 --tls.certfiles tls-root-cert/tls-ca-cert.pem --enrollment.profile tls --csr.hosts 'host1,*.ordererOrg1.example.com' --mspdir tls-ca/rcaadmin/msp
```

## Organization CA
Steps refer to tutorial on TLS CA, `org-ca.md`:

0. Before you begin

```bash
mkdir organizations/ordererOrganizations/org-ca.ordererOrg1.example.com/
mkdir organizations/ordererOrganizations/org-ca.ordererOrg1.example.com/tls
sudo cp organizations/ordererOrganizations/tls-ca-client.ordererOrg1.example.com/tls-ca/rcaadmin/msp/signcerts/cert.pem organizations/ordererOrganizations/org-ca.ordererOrg1.example.com/tls 
sudo cp organizations/ordererOrganizations/tls-ca-client.ordererOrg1.example.com/tls-ca/rcaadmin/msp/keystore/$(sudo ls organizations/ordererOrganizations/tls-ca-client.ordererOrg1.example.com/tls-ca/rcaadmin/msp/keystore) organizations/ordererOrganizations/org-ca.ordererOrg1.example.com/tls/key.pem
```

1. Initialize the CA server

```bash
docker run --rm --name org-ca.ordererOrg1.example.com -v ${PWD}/organizations/ordererOrganizations/org-ca.ordererOrg1.example.com:/root/ca-server hyperledger/fabric-ca:1.4.9 fabric-ca-server init -b rcaadmin:rcaadminpw -H /root/ca-server
```

2. Modify the CA server configuration

As we did with the TLS CA, we need to edit the generated `fabric-ca-server-config.yaml` file for the organization CA to modify the default configuration settings for your use case according to the Checklist for a production CA server.
Edit the `fabric-ca-server-config.yaml` in `organizations/ordererOrganizations/org-ca.ordererOrg1.example.com` folder.
```bash
sudo chown -R $USER:$USER organizations
cloudshell edit organizations/ordererOrganizations/org-ca.ordererOrg1.example.com/fabric-ca-server-config.yaml
```

or <walkthrough-editor-open-file filePath="organizations/ordererOrganizations/org-ca.ordererOrg1.example.com/fabric-ca-server-config.yaml" text="Open config file"></walkthrough-editor-open-file>

with:

**`port`** - 7055

**`tls.enabled`** - `true`.

**`tls.certfile`** - `tls/cert.pem` 

**`tls.keyfile`** - `tls/key.pem`

**`ca.name`** - `org-ca.ordererOrg1.example.com`

**`csr.cn`** - `org-ca.ordererOrg1.example.com`

**`csr.hosts`** - add `'*.ordererOrg1.example.com'`

3. Delete the CA server certificates

```bash
sudo rm organizations/ordererOrganizations/org-ca.ordererOrg1.example.com/ca-cert.pem
sudo rm -rf organizations/ordererOrganizations/org-ca.ordererOrg1.example.com/msp
```

4. Start the CA server

```bash
docker run --rm -p 7055:7055 --name org-ca.ordererOrg1.example.com -v ${PWD}/organizations/ordererOrganizations/org-ca.ordererOrg1.example.com:/root/ca-server hyperledger/fabric-ca:1.4.9 fabric-ca-server start -H /root/ca-server
```

5. Enroll the CA admin

```bash
mkdir organizations/ordererOrganizations/org-ca-client.ordererOrg1.example.com/
mkdir organizations/ordererOrganizations/org-ca-client.ordererOrg1.example.com/orderer-ca
mkdir organizations/ordererOrganizations/org-ca-client.ordererOrg1.example.com/tls-root-cert
cp organizations/ordererOrganizations/tls-ca.ordererOrg1.example.com/ca-cert.pem organizations/ordererOrganizations/org-ca-client.ordererOrg1.example.com/tls-root-cert/tls-ca-cert.pem
docker run --rm --name org-ca-client.ordererOrg1.example.com --link org-ca.ordererOrg1.example.com:org-ca.ordererOrg1.example.com -v ${PWD}/organizations/ordererOrganizations/org-ca-client.ordererOrg1.example.com:/root/ca-client -e FABRIC_CA_CLIENT_HOME=/root/ca-client hyperledger/fabric-ca:1.4.9 fabric-ca-client enroll -d -u https://rcaadmin:rcaadminpw@org-ca.ordererOrg1.example.com:7055 --tls.certfiles tls-root-cert/tls-ca-cert.pem --csr.hosts 'host1,org-ca.ordererOrg1.example.com' --mspdir orderer-ca/rcaadmin/msp
```

6. [Use the CA to create identities and MSPs](https://hyperledger-fabric.readthedocs.io/en/release-2.3/deployment_guide_overview.html#step-four-use-the-ca-to-create-identities-and-msps)

```bash
sudo cp organizations/ordererOrganizations/org-ca-client.ordererOrg1.example.com/orderer-ca/rcaadmin/msp/keystore/$(sudo ls organizations/ordererOrganizations/org-ca-client.ordererOrg1.example.com/orderer-ca/rcaadmin/msp/keystore) organizations/ordererOrganizations/org-ca-client.ordererOrg1.example.com/orderer-ca/rcaadmin/msp/keystore/key.pem
```

- Register and enroll an admin identity and create an MSP

```bash
docker run --rm --name org-ca-client.ordererOrg1.example.com --link org-ca.ordererOrg1.example.com:org-ca.ordererOrg1.example.com -v ${PWD}/organizations/ordererOrganizations/org-ca-client.ordererOrg1.example.com:/root/ca-client -e FABRIC_CA_CLIENT_HOME=/root/ca-client hyperledger/fabric-ca:1.4.9 fabric-ca-client register -d --id.name orgadmin --id.secret orgadminpw --id.type admin -u https://org-ca.ordererOrg1.example.com:7055  --tls.certfiles tls-root-cert/tls-ca-cert.pem --mspdir orderer-ca/rcaadmin/msp
docker run --rm --name org-ca-client.ordererOrg1.example.com --link org-ca.ordererOrg1.example.com:org-ca.ordererOrg1.example.com -v ${PWD}/organizations/ordererOrganizations/org-ca-client.ordererOrg1.example.com:/root/ca-client -e FABRIC_CA_CLIENT_HOME=/root/ca-client hyperledger/fabric-ca:1.4.9 fabric-ca-client enroll -d -u https://orgadmin:orgadminpw@org-ca.ordererOrg1.example.com:7055 --tls.certfiles tls-root-cert/tls-ca-cert.pem --csr.hosts 'host1,org-ca.ordererOrg1.example.com' --mspdir orderer-ca/orgadmin/msp
```

- Register and enroll node identities

```bash
docker run --rm --name tls-ca-client.ordererOrg1.example.com --link tls-ca.ordererOrg1.example.com:tls-ca.ordererOrg1.example.com -v ${PWD}/organizations/ordererOrganizations/tls-ca-client.ordererOrg1.example.com:/root/ca-client -e FABRIC_CA_CLIENT_HOME=/root/ca-client  hyperledger/fabric-ca:1.4.9 fabric-ca-client register -d --id.name osn1 --id.secret osn1pw -u https://tls-ca.ordererOrg1.example.com:7054  --tls.certfiles tls-root-cert/tls-ca-cert.pem --mspdir tls-ca/tlsadmin/msp
docker run --rm --name tls-ca-client.ordererOrg1.example.com --link tls-ca.ordererOrg1.example.com:tls-ca.ordererOrg1.example.com -v ${PWD}/organizations/ordererOrganizations/tls-ca-client.ordererOrg1.example.com:/root/ca-client -e FABRIC_CA_CLIENT_HOME=/root/ca-client hyperledger/fabric-ca:1.4.9 fabric-ca-client enroll -d -u https://osn1:osn1pw@tls-ca.ordererOrg1.example.com:7054 --tls.certfiles tls-root-cert/tls-ca-cert.pem --enrollment.profile tls --csr.hosts 'host1,*.ordererOrg1.example.com' --mspdir tls-ca/osn1.ordererOrg1.example.com/msp
```

```bash
sudo cp organizations/ordererOrganizations/tls-ca-client.ordererOrg1.example.com/tls-ca/rcaadmin/msp/keystore/$(sudo ls organizations/ordererOrganizations/tls-ca-client.ordererOrg1.example.com/tls-ca/rcaadmin/msp/keystore) organizations/ordererOrganizations/org-ca.ordererOrg1.example.com/tls/key.pem
```

```bash
docker run --rm --name org-ca-client.ordererOrg1.example.com --link org-ca.ordererOrg1.example.com:org-ca.ordererOrg1.example.com -v ${PWD}/organizations/ordererOrganizations/org-ca-client.ordererOrg1.example.com:/root/ca-client -e FABRIC_CA_CLIENT_HOME=/root/ca-client hyperledger/fabric-ca:1.4.9 fabric-ca-client register -d --id.name osn1 --id.secret osn1pw --id.type orderer -u https://org-ca.ordererOrg1.example.com:7055  --tls.certfiles tls-root-cert/tls-ca-cert.pem --mspdir orderer-ca/rcaadmin/msp
docker run --rm --name org-ca-client.ordererOrg1.example.com --link org-ca.ordererOrg1.example.com:org-ca.ordererOrg1.example.com -v ${PWD}/organizations/ordererOrganizations/org-ca-client.ordererOrg1.example.com:/root/ca-client -e FABRIC_CA_CLIENT_HOME=/root/ca-client hyperledger/fabric-ca:1.4.9 fabric-ca-client enroll -d -u https://osn1:osn1pw@org-ca.ordererOrg1.example.com:7055 --tls.certfiles tls-root-cert/tls-ca-cert.pem --csr.hosts 'host1,org-ca.ordererOrg1.example.com' --mspdir orderer-ca/osn1.ordererOrg1.example.com/msp
```

## [TLS certificates](https://hyperledger-fabric.readthedocs.io/en/release-2.3/deployorderer/ordererdeploy.html#tls-certificates)

- Copy the **TLS CA Root certificate**, which by default is called `ca-cert.pem`, to the orderer organization MSP definition `organizations/ordererOrganizations/ordererOrg1.example.com/msp/tlscacerts/tls-cert.pem`.

```bash
mkdir organizations/ordererOrganizations/ordererOrg1.example.com organizations/ordererOrganizations/ordererOrg1.example.com/msp organizations/ordererOrganizations/ordererOrg1.example.com/msp/tlscacerts
cp organizations/ordererOrganizations/tls-ca.ordererOrg1.example.com/ca-cert.pem organizations/ordererOrganizations/ordererOrg1.example.com/msp/tlscacerts/tls-cert.pem
```

- Copy the **CA Root certificate**, which by default is called `ca-cert.pem`, to the orderer organization MSP definition `organizations/ordererOrganizations/ordererOrg1.example.com/msp/cacerts/ca-cert.pem`.

```bash
mkdir organizations/ordererOrganizations/ordererOrg1.example.com/msp/cacerts
cp organizations/ordererOrganizations/org-ca.ordererOrg1.example.com/ca-cert.pem organizations/ordererOrganizations/ordererOrg1.example.com/msp/cacerts/ca-cert.pem
```

- When you enroll the orderer identity with the TLS CA, the public key is generated in the `signcerts` folder, and the private key is located in the `keystore` directory. Rename the private key in the `keystore` folder to `orderer0-tls-key.pem` so that it can be easily recognized later as the TLS private key for this node.

- Copy the orderer TLS certificate and private key files to `organizations/ordererOrganizations/ordererOrg1.example.com/orderers/orderer0.ordererOrg1.example.com/tls`. The path and name of the certificate and private key files correspond to the values of the `General.TLS.Certificate` and `General.TLS.PrivateKey` parameters in the `orderer.yaml`.

```bash
mkdir organizations/ordererOrganizations/ordererOrg1.example.com/orderers organizations/ordererOrganizations/ordererOrg1.example.com/orderers/orderer0.ordererOrg1.example.com organizations/ordererOrganizations/ordererOrg1.example.com/orderers/orderer0.ordererOrg1.example.com/tls
sudo cp organizations/ordererOrganizations/tls-ca.ordererOrg1.example.com/ca-cert.pem organizations/ordererOrganizations/ordererOrg1.example.com/orderers/orderer0.ordererOrg1.example.com/tls/tls-cert.pem
sudo cp organizations/ordererOrganizations/tls-ca-client.ordererOrg1.example.com/tls-ca/osn1.ordererOrg1.example.com/msp/signcerts/cert.pem organizations/ordererOrganizations/ordererOrg1.example.com/orderers/orderer0.ordererOrg1.example.com/tls/
sudo cp organizations/ordererOrganizations/tls-ca-client.ordererOrg1.example.com/tls-ca/osn1.ordererOrg1.example.com/msp/keystore/$(sudo ls organizations/ordererOrganizations/tls-ca-client.ordererOrg1.example.com/tls-ca/osn1.ordererOrg1.example.com/msp/keystore/) organizations/ordererOrganizations/ordererOrg1.example.com/orderers/orderer0.ordererOrg1.example.com/tls/orderer0-tls-key.pem
```

**Note**: Don’t forget to create the `config.yaml` file and add it to the organization MSP and local MSP folder for each ordering node. This file enables Node OU support for the MSP, an important feature that allows the MSP’s admin to be identified based on an “admin” OU in an identity’s certificate. Learn more in the [Fabric CA documentation](https://hyperledger-fabric-ca.readthedocs.io/en/release-1.4/deployguide/use_CA.html#nodeous).

```bash
sudo chown -R $USER:$USER organizations
touch organizations/ordererOrganizations/ordererOrg1.example.com/orderers/orderer0.ordererOrg1.example.com/msp/config.yaml
cloudshell edit organizations/ordererOrganizations/ordererOrg1.example.com/orderers/orderer0.ordererOrg1.example.com/msp/config.yaml
```

and put this information into the file:

```terminal
NodeOUs:
 Enable: true
 ClientOUIdentifier:
   Certificate: cacerts/org-ca-ordererOrg1-example-com-7055.pem
   OrganizationalUnitIdentifier: client
 PeerOUIdentifier:
   Certificate: cacerts/org-ca-ordererOrg1-example-com-7055.pem
   OrganizationalUnitIdentifier: peer
 AdminOUIdentifier:
   Certificate: cacerts/org-ca-ordererOrg1-example-com-7055.pem
   OrganizationalUnitIdentifier: admin
 OrdererOUIdentifier:
   Certificate: cacerts/org-ca-ordererOrg1-example-com-7055.pem
   OrganizationalUnitIdentifier: orderer 
```

## [Orderer local MSP (enrollment certificate and private key)](https://hyperledger-fabric.readthedocs.io/en/release-2.3/deployorderer/ordererdeploy.html#orderer-local-msp-enrollment-certificate-and-private-key)

Copy the MSP folder to `organizations/ordererOrganizations/ordererOrg1.example.com/orderers/orderer0.ordererOrg1.example.com/msp`. This path corresponds to the value of the `General.LocalMSPDir` parameter in the `orderer.yaml` file. Because of the Fabric concept of “[Node Organization Unit (OU)](https://hyperledger-fabric-ca.readthedocs.io/en/release-1.4/deployguide/use_CA.html#nodeous)”, you do not need to specify an admin of the orderer when bootstrapping. Rather, the role of “admin” is conferred onto an identity by setting an OU value of “admin” inside a certificate and enabled by the `config.yaml` file. When Node OUs are enabled, any admin identity from this organization will be able to administer the orderer.

```bash
sudo cp organizations/ordererOrganizations/org-ca-client.ordererOrg1.example.com/orderer-ca/osn1.ordererOrg1.example.com/msp/keystore/$(sudo ls organizations/ordererOrganizations/org-ca-client.ordererOrg1.example.com/orderer-ca/osn1.ordererOrg1.example.com/msp/keystore/) organizations/ordererOrganizations/org-ca-client.ordererOrg1.example.com/orderer-ca/osn1.ordererOrg1.example.com/msp/keystore/key.pem
sudo cp -r organizations/ordererOrganizations/org-ca-client.ordererOrg1.example.com/orderer-ca/osn1.ordererOrg1.example.com/msp organizations/ordererOrganizations/ordererOrg1.example.com/orderers/orderer0.ordererOrg1.example.com/
```

## [Storage](https://hyperledger-fabric.readthedocs.io/en/release-2.3/deployorderer/ordererdeploy.html#storage)

Provision persistent storage for your ledgers. The default location for the ledger is located at `/var/hyperledger/production/orderer`. Ensure that your orderer has write access to the folder. If you choose to use a different location, provide that path in the `FileLedger:` parameter in the `orderer.yaml` file, or pass with `ORDERER_FILELEDGER_LOCATION` environment variable. If you decide to use Kubernetes or Docker, recall that in a containerized environment, local storage disappears when the container goes away, so you will need to provision or mount persistent storage for the ledger before you deploy an orderer.

```bash
docker volume create orderer0.ordererOrg1.example.com
```

## Create `orderer.yaml`

Look at [Configuration of `orderer.yaml`](https://hyperledger-fabric.readthedocs.io/en/release-2.3/deployorderer/ordererdeploy.html#configuration-of-orderer-yaml) and set all of the parameters.

The properties in `orderer.yaml` can be overrided by environment variable. The environment variable name is started with `ORDERER_`, all capital letter and joined together with underscore ('_'). For example:
- `General.ListenAddress` in `orderer.yaml` will be `ORDERER_GENERAL_LISTENADDRESS`
- `ChannelParticipation.Enabled` in `orderer.yaml` will be `ORDERER_CHANNELPARTICIPATION_ENABLED`

We will use `orderer.yaml` in `fabric-samples/config` and override some parameters.
```bash
mkdir config
cp -r fabric-samples/config .
```
## [Start the orderer](https://hyperledger-fabric.readthedocs.io/en/release-2.3/deployorderer/ordererdeploy.html#start-the-orderer)

```bash
docker run --rm -itd --name osn1.ordererOrg1.example.com -v ${PWD}/config:/config -v orderer0.ordererOrg1.example.com:/var/hyperledger/production/orderer -v ${PWD}/system-genesis-block/genesis.block:/var/hyperledger/orderer/orderer.genesis.block -v ${PWD}/organizations/ordererOrganizations/ordererOrg1.example.com/orderers/orderer0.ordererOrg1.example.com/msp:/var/hyperledger/orderer/msp -v ${PWD}/organizations/ordererOrganizations/ordererOrg1.example.com/orderers/orderer0.ordererOrg1.example.com/tls/:/var/hyperledger/orderer/tls -e FABRIC_CFG_PATH=/config -e ORDERER_GENERAL_BOOTSTRAPMETHOD=none -e ORDERER_CHANNELPARTICIPATION_ENABLED=true -e ORDERER_ADMIN_LISTENADDRESS=0.0.0.0:7053 -e ORDERER_ADMIN_TLS_ENABLED=true -e ORDERER_ADMIN_TLS_CERTIFICATE=/var/hyperledger/orderer/tls/cert.pem -e ORDERER_ADMIN_TLS_PRIVATEKEY=/var/hyperledger/orderer/tls/orderer0-tls-key.pem -e ORDERER_ADMIN_TLS_ROOTCAS=[/var/hyperledger/orderer/tls/tls-cert.pem] -e ORDERER_ADMIN_TLS_CLIENTAUTHREQUIRED=true -e ORDERER_GENERAL_LISTENADDRESS=0.0.0.0 -e ORDERER_GENERAL_LISTENPORT=7050 -e ORDERER_GENERAL_LOCALMSPID=OrdererMSP -e ORDERER_GENERAL_LOCALMSPDIR=/var/hyperledger/orderer/msp -e ORDERER_GENERAL_TLS_ENABLED=true -e ORDERER_GENERAL_TLS_PRIVATEKEY=/var/hyperledger/orderer/tls/orderer0-tls-key.pem -e ORDERER_GENERAL_TLS_CERTIFICATE=/var/hyperledger/orderer/tls/cert.pem -e ORDERER_GENERAL_TLS_ROOTCAS=[/var/hyperledger/orderer/tls/tls-cert.pem] hyperledger/fabric-orderer:2.3.0
```

## [Next steps](https://hyperledger-fabric.readthedocs.io/en/release-2.3/deployorderer/ordererdeploy.html#next-steps)
Look at [Step three: Join additional ordering nodes](https://hyperledger-fabric.readthedocs.io/en/release-2.3/create_channel/create_channel_participation.html)
