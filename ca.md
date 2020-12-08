# Certificate Authorities (CA)

[Certificate Authorities or CA](https://hyperledger-fabric.readthedocs.io/en/latest/identity/identity.html#certificate-authorities) is the system to provides the features such as:

- registration of [identities](https://hyperledger-fabric.readthedocs.io/en/latest/identity/identity.html), or connects to [LDAP](https://en.wikipedia.org/wiki/Lightweight_Directory_Access_Protocol) as the user registry
- issuance of Enrollment Certificates (ECerts)
- certificate renewal and revocation

Hyperledger Fabric provides CA server, client, and SDK for the fabric network.
However, in development and testing environments, cryptogen tool is recommended to be used instead of CAs.

## Identity

Digital identity can be implemented in multiple ways. The identities used for [authentication](https://en.wikipedia.org/wiki/Multi-factor_authentication) can be:

- **Something you have**: Some physical object in the possession of the user, such as a security token (USB stick), a bank card, a key, etc.
- **Something you know**: Certain knowledge only known to the user, such as a password, PIN, TAN, etc.
- **Something you are**: Some physical characteristic of the user (biometrics), such as a fingerprint, eye iris, voice, typing speed, pattern in key press intervals, etc.
- **Somewhere you are**: Some connection to a specific computing network or using a GPS signal to identify the location.

Hyperledger Fabric use [asymmetric cryptography](https://en.wikipedia.org/wiki/Public-key_cryptography) to generate public and private keys, then verify private key encryption by decryption using public key. The private key is something **ONLY** you know.

Try to create public/private key at [andersbrownworth.com](https://andersbrownworth.com/blockchain/public-private-keys/keys)

Click `Random` in the page, then the private key and the public key will be changed. The private key have to be keep as secret.

Hyperledger Fabric network uses [public key infrastructure](https://en.wikipedia.org/wiki/Public_key_infrastructure) to verify the actions of all network participants.

## Digital Signature

Try to use created public/private key at [andersbrownworth.com](https://andersbrownworth.com/blockchain/public-private-keys/keys) to sign the message by:

1. Click `Signatures` at top-right, then the page will be changed.  
2. Type your message in `Message` and click `Sign` below, then the Message Signature will be shown.
3. Click `Verify` tab and click `Verify` button, then the background will be changed into green color.
4. Try to change `Message` or `Public Key` or `Signature` then click `Verify` button again, then the background will be changed into the red color.
5. Try to change data back to the correct one and click `Verify` button again, then the background will be changed into green color.  

To understand more about digital signature, try [![Open In Colab](https://colab.research.google.com/assets/colab-badge.svg)](https://gist.github.com/ioisup/5c8d043619ca54eba0a24b3e091cfba9)

## Certificate

### Certificate format

Certificate is document that prove something. [Public key certificate](https://en.wikipedia.org/wiki/Public_key_certificate) is an [electronic document](https://en.wikipedia.org/wiki/Electronic_document) used to prove the ownership of a public key. The most common format is [X.509](https://en.wikipedia.org/wiki/X.509) that used in many Internet protocols, including TLS/SSL, which is the basis for HTTPS.

The structure of an X.509 v3 digital certificate is as follows:

- Certificate
  - Version Number
  - Serial Number
  - Signature Algorithm ID
  - Issuer Name
  - Validity period
    - Not Before
    - Not After
  - Subject name
  - Subject Public Key Info
    - Public Key Algorithm
    - Subject Public Key
  - Issuer Unique Identifier (optional)
  - Subject Unique Identifier (optional)
  - Extensions (optional)
- Certificate Signature Algorithm
- Certificate Signature

### Create self-signed certificate

The OpenSSL can be used to create [self-signed certificate](https://en.wikipedia.org/wiki/Self-signed_certificate) by using the follow command:

```bash
openssl req -new -newkey rsa:4096 -x509 -sha256 -days 365 -nodes -out MyCertificate.crt -keyout MyKey.key
```

Additional identifying information will be prompted to input into the certificate.

The following is the OpenSSL options used in this command:

- newkey rsa:4096 : Create a 4096 bit RSA key for use with the certificate.
- x509 : Create x509 certificate.
- sha256 : Generate the certificate request using 265-bit [SHA](https://en.wikipedia.org/wiki/Secure_Hash_Algorithms).
- days : Determines the length of time in days that the certificate is being issued for. 
- nodes : Create a certificate that does not require a passphrase.

The file `MyCertificate.crt` contains X.509 certificate in base64 encode, and the file `MyKey.key` contains base64 encoded private key.

## Certificate Authorities (CAs)

[![Hyperledger Fabric CAs](https://hyperledger-fabric-ca.readthedocs.io/en/latest/_images/fabric-ca.png)](https://hyperledger-fabric-ca.readthedocs.io/en/latest/users-guide.html#overview)

The FABRIC_CA_HOME environment variable contains `/etc/hyperledger/fabric-ca-server` which is the CA server's home folder.


```bash
docker run -it --rm --name fabric-ca-server-init -v ${PWD}/ca-server:/etc/hyperledger/fabric-ca-server hyperledger/fabric-ca:amd64-1.4.9 sh
```

## Initializing the server
Initialize the Fabric CA server as follows:

```bash
docker run --rm --name fabric-ca-server-init -v ${PWD}/ca-server:/root/ca-server hyperledger/fabric-ca:amd64-1.4.9 fabric-ca-server init -b admin:adminpw -H /root/ca-server
```

The -b (bootstrap identity) option is required for initialization when LDAP is disabled. At least one bootstrap identity is required to start the Fabric CA server; this identity is the server administrator.

The -H(, --home string) option is for set server's home directory (default "/etc/hyperledger/fabric-ca-server")

Then look at folder ca-server you will see:
- `ca-cert.pem` : [Private Exchange Mail](https://en.wikipedia.org/wiki/Privacy-Enhanced_Mail) format contains a base64 translation of the x509 ASN certificate
- `fabric-ca-server-config.yaml` : configuration file for fabric CA server 
- `fabric-ca-server.db` : SQLite database file for fabric CA server. Have to be changed into PostgreSQL or MySQL for clustered CA.
- `IssuerPublicKey` :  
- `IssuerRevocationPublicKey`:  
- `msp` : folder contains `keystore` folder
  - `keystore` : folder contains private keys
    - `a96ee445f6115d84091796e95a4ddcf13f3947f74c4d7e8e7426cac3f24b8062_sk`
    - `IssuerRevocationPrivateKey` : base64 private key
    - `IssuerSecretKey` : private key

## Start server

```bash
docker run -it --rm --name fabric-ca -v ${PWD}/ca-server:/root/ca-server hyperledger/fabric-ca:amd64-1.4.9 fabric-ca-server start -b admin:adminpw -H /root/ca-server
```

## Connect client to server
### Enroll first admin
```bash
docker exec -it fabric-ca FABRIC_CA_CLIENT_HOME=/root/ca-server/clients/admin fabric-ca-client enroll -u http://admin:adminpw@localhost:7054
```

```bash
export FABRIC_CA_CLIENT_HOME=$HOME/ca-server/clients/admin
fabric-ca-client enroll -u http://admin:adminpw@localhost:7054
```

The server will show:
```
signed certificate with serial number =======================
127.0.0.1:55964 POST /enroll 201 0 "OK"
```

### Register and enroll second admin

To register new user:
```bash
fabric-ca-client register --id.name admin2 --id.affiliation org1.department1 --id.attrs 'hf.Revoker=true,admin=true:ecert'
```

The password will be shown in the client screen and the server will show:

```
127.0.0.1:56040 POST /register 201 0 "OK"
```

Copy the command below and replace [PASSWORD] with the shown password
```bash
fabric-ca-client enroll -u http://admin2:[PASSWORD]]@localhost:7054
```

The server will show:

```
signed certificate with serial number =======================
127.0.0.1:56062 POST /enroll 201 0 "OK"
```
