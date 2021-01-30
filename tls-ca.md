# Deploy TLS CA

[![Open this project in Cloud
Shell](http://gstatic.com/cloudssh/images/open-btn.png)](https://console.cloud.google.com/cloudshell/open?git_repo=https://github.com/incubate-co-th/fabric-course.git&page=editor&tutorial=tls-ca.md)


Follow steps from [CA Deployment steps](https://hyperledger-fabric-ca.readthedocs.io/en/latest/deployguide/cadeploy.html).

# Steps
The [docker image](https://hub.docker.com/r/hyperledger/fabric-ca) from Hyperledger will be used instead of binary files.

The server-side TLS CA named `ca1tls` will be created by:

1. Initialize the CA server
2. Modify the CA server configuration
3. Delete the CA server certificates
4. Start the CA server
5. Enroll bootstrap user with TLS CA

## Step 1: Initialize the CA server

### Initialize the Fabric CA server as follows:

```bash
docker run --rm --name fabric-ca-server-tls-init.org1 -v ${PWD}/Organizations/org1/fabric-ca-server-tls:/root/fabric-ca-server-tls hyperledger/fabric-ca:1.4.9 fabric-ca-server init -b tls-admin:tls-adminpw -H /root/fabric-ca-server-tls
```

The -b (bootstrap identity) option is required for initialization when LDAP is disabled. At least one bootstrap identity is required to start the Fabric CA server; this identity is the server administrator.

The -H(, --home string) option is for set server's home directory (default "/etc/hyperledger/fabric-ca-server")

## Step 2: Modify the CA server configuration

Edit the `fabric-ca-server-config.yaml` in `fabric-ca-server-tls` folder.
```bash
sudo chown -R $USER:$USER Organizations
cloudshell edit Organizations/org1/fabric-ca-server-tls/fabric-ca-server-config.yaml
```

or <walkthrough-editor-open-file filePath="Organizations/org1/fabric-ca-server-tls/fabric-ca-server-config.yaml" text="Open config file"></walkthrough-editor-open-file>

### Port

**`port`** - Enter the port that you want to use for this server. Try to change to `7054`.

### TLS Enabled
**`tls.enabled`** - Enable by setting this value to `true`. Setting this value to true causes the TLS signed certificate `tls-cert.pem` file to be generated when the server is started in the next step.

### CA Name
**`ca.name`** - Give the CA a name by editing the parameter, for example `org1-tls-ca`.

### CSR Hosts
**`csr.hosts`** - Update this parameter to include this hostname and ip address where this server is running, if it is different than what is already in this file.

### Singing Profiles
**`signing.profiles.ca`** - Since this is a TLS CA that will not issue CA certificates, the ca profiles section can be removed. The `signing.profiles` block should only contain tls profile.

### Operations Listen Address
**`operations.listenAddress`**: - In the unlikely case that there is another node running on this host and port, then you need to update this parameter to use a different port.

Then save the file and go to next step.

## Step 3: Delete the CA server certificates

Delete:
- the fabric-ca-server-tls/ca-cert.pem file and, 
- the entire fabric-ca-server-tls/msp folder.

### Delete fabric-ca-server-tls/ca-cert.pem file
Run the command below:
```bash
sudo rm Organizations/org1/fabric-ca-server-tls/ca-cert.pem
```
### Delete fabric-ca-server-tls/msp folder
Run the command below:
```bash
sudo rm -rf Organizations/org1/fabric-ca-server-tls/msp
```

## Step 4: Start the CA server
Run the command below to start CA in docker containner in new cloudshell:
```bash
docker run --rm -p 7054:7054 --name fabric-ca-server-tls.org1 -v ${PWD}/Organizations/org1/fabric-ca-server-tls:/root/fabric-ca-server-tls hyperledger/fabric-ca:1.4.9  fabric-ca-server start -b tls-admin:tls-adminpw -H /root/fabric-ca-server-tls
```

## Step 5: Enroll bootstrap user with TLS CA 

### Create folder for CA client
```bash
mkdir Organizations/org1/fabric-ca-client
mkdir Organizations/org1/fabric-ca-client/tls-ca
mkdir Organizations/org1/fabric-ca-client/tls-root-cert
```
### Copy the TLS CA root certificate file
```bash
cp Organizations/org1/fabric-ca-server-tls/ca-cert.pem Organizations/org1/fabric-ca-client/tls-root-cert/tls-ca-cert.pem
```

### Set environment variable FABRIC_CA_CLIENT_HOME for docker and enroll admin user

```bash
docker run --rm --name fabric-ca-client.org1 --link fabric-ca-server-tls.org1:fabric-ca-server-tls.org1 -v ${PWD}/Organizations/org1/fabric-ca-client:/root/fabric-ca-client -e FABRIC_CA_CLIENT_HOME=/root/fabric-ca-client  hyperledger/fabric-ca:1.4.9 fabric-ca-client enroll -d -u https://tls-admin:tls-adminpw@fabric-ca-server-tls.org1:7054 --tls.certfiles tls-root-cert/tls-ca-cert.pem --enrollment.profile tls --csr.hosts 'host1,fabric-ca-server-tls.org1' --mspdir tls-ca/tlsadmin/msp
```

When this command completes successfully, the fabric-ca-client/tls-ca/tlsadmin/msp folder is generated and contains the signed cert and private key for the TLS CA admin identity. If the enroll command fails for some reason, to avoid confusion later, please remove the generated private key from the fabric-ca-client/tls-ca/admin/msp/keystore folder before reattempting the enroll command.

### Review the Steps

[![All Steps](https://hyperledger-fabric-ca.readthedocs.io/en/latest/_images/ca-tls-flow.png)](https://hyperledger-fabric-ca.readthedocs.io/en/latest/deployguide/cadeploy.html)

### Register and enroll the organization CA bootstrap identity with the TLS CA

The TLS CA server was started with a bootstrap identity which has full admin privileges for the server. One of the key abilities of the admin is the ability to register new identities. Each node in the organization that transacts on the network needs to register with the TLS CA. Therefore, before we set up the organization CA, we need to use the TLS CA to register and enroll the organization CA bootstrap identity to get its TLS certificate and private key. The following command registers the organization CA bootstrap identity rcaadmin and rcaadminpw with the TLS CA.

```bash
docker run --rm --name fabric-ca-client.org1 --link fabric-ca-server-tls.org1:fabric-ca-server-tls.org1 -v ${PWD}/Organizations/org1/fabric-ca-client:/root/fabric-ca-client -e FABRIC_CA_CLIENT_HOME=/root/fabric-ca-client  hyperledger/fabric-ca:1.4.9 fabric-ca-client register -d --id.name rcaadmin --id.secret rcaadminpw -u https://fabric-ca-server-tls.org1:7054  --tls.certfiles tls-root-cert/tls-ca-cert.pem --mspdir tls-ca/tlsadmin/msp
```

Notice that the --mspdir flag on the command points to the location of TLS CA admin msp certificates that we generated in the previous step. This crypto material is required to be able to register other users with the TLS CA.

Next, we need to enroll the rcaadmin user to generate the TLS certificates for the identity. In this case, we use the --mspdir flag on the enroll command to designate where the generated organization CA TLS certificates should be stored for the rcaadmin user. Because these certificates are for a different identity, it is a best practice to put them in their own folder. Therefore, instead of generating them in the default msp folder, we will put them in a new folder named rcaadmin that resides along side the tlsadmin folder.

```bash
docker run --rm --name fabric-ca-client.org1 --link fabric-ca-server-tls.org1:fabric-ca-server-tls.org1 -v ${PWD}/Organizations/org1/fabric-ca-client:/root/fabric-ca-client -e FABRIC_CA_CLIENT_HOME=/root/fabric-ca-client  hyperledger/fabric-ca:1.4.9 fabric-ca-client enroll -d -u https://rcaadmin:rcaadminpw@fabric-ca-server-tls.org1:7054 --tls.certfiles tls-root-cert/tls-ca-cert.pem --enrollment.profile tls --csr.hosts 'host1,*.example.com' --mspdir tls-ca/rcaadmin/msp
```

In this case, the --mspdir flag works a little differently. For the enroll command, the --mspdir flag indicates where to store the generated certificates for the rcaadmin identity.

**Important**: The organization CA TLS signed certificate is generated under fabric-ca-client/tls-ca/rcaadmin/msp/signcert and the private key is available under fabric-ca-client/tls-ca/rcaadmin/msp/keystore. When you deploy the organization CA you will need to point to the location of these two files in the tls section of the CA configuration .yaml file. For ease of reference, you can rename the file in the keystore folder to key.pem.
