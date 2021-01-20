# Hyperledger Fabric Prerequisites

[![Open this project in Cloud
Shell](http://gstatic.com/cloudssh/images/open-btn.png)](https://console.cloud.google.com/cloudshell/open?git_repo=https://github.com/incubate-co-th/fabric-course.git&page=editor&tutorial=prerequisites.md)

## We need some tools and files:
- git
- cURL
- Docker and Docker Compose
- NodeJS and NPM
- Sample, binary and docker images

You can click icon <walkthrough-cloud-shell-icon></walkthrough-cloud-shell-icon> after the command to send the command to cloudshell.

## Git

Check git version with command:

```bash
git --version
```

We need at lease version 2.20.1

## cURL

Check cURL version with command:

```bash
curl --version
```

We need at lease version 7.64.0

## Docker and Docker Compose

Check Docker version with command:

```bash
docker --version
```

We need at lease version 17.06.2

Check Docker Compose version with command:

```bash
docker-compose --version
```

We need at lease version 1.14.0

## NodeJS and NPM

Check NodeJS version with command:

```bash
node -v
```

We need at lease version 10.14.2

Check NPM version with command:

```bash
npm -v
```

We need at lease version 6.14.8

## Install Samples, Binaries, and Docker Images

The command below demonstrates how to download the latest production releases when created this document - Fabric v2.3.0 and Fabric CA v1.4.9

```bash
curl -sSL https://bit.ly/2ysbOFE | bash -s -- 2.3.0 1.4.9
```

Add installed binary into PATH environment variable

```bash
export PATH=${PWD}/fabic-sample/bin:$PATH
```
