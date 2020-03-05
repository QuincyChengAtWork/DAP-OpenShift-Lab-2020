# DAP OpenShift Lab 2020
This is a tutorial on how to secure secrets of OpenShift applications by CyberArk Dynamic Access Provider (DAP).   
We will cover deploying DAP follower instances manually, and by follower seed fetcher.
Secretless Broker & inital container will also be covered in this tutorial.

Extra tech challenges will be included in each sections for quick learners.

## Overview

[OKD](https://www.okd.io) is used as the OpenShift platform to host the [demo app](https://github.com/jeepapichet/cityapp)
The application will connect to a MySQL database to retreive data, and during authenication, [secrets](https://docs.cyberark.com/Product-Doc/OnlineHelp/AAM-DAP/Latest/en/Content/Get%20Started/key_concepts/secrets.html) will be used by the application.

[Dynamic Access Provider (DAP)](https://docs.cyberark.com/Product-Doc/OnlineHelp/AAM-DAP/Latest/en/Content/Get%20Started/WhatIsConjur.html) is used in this tutorial to secure & manage the secrets.   


## Architecture

![Architecture](https://github.com/QuincyChengAtWork/DAP-OpenShift-Lab-2020/raw/master/images/architecture.png)


## Technical Procedure

### Prerequisite
 - Access to Smartfile
 - FTP client
 - 7zip or Winzip installed on your workstation
 - VMware Workstation 12 or greater installed on your workstation
 - CyberArk CorePAS installed on VMWare workstation, `CGD-2020-0101-GA` prefered 
 - Sufficient disk space for additional 2 virtual machines (5.6GB for compressed VM and/or 24GB for extracted VM)

### [Preparation: Environment Setup](00-setup.md)
1. Setup CyberArk CorePAS based on CGD
2. Setup 2 Extra VM (DAP Master & OKD)
3. Onboard MySQL Account to CorePAS
4. Setup DAP Master
5. Configure Vault Synchronizer

### [Lab 1: OpenShift Fundamental - App with embedded secret](01-lab1.md)
1. Login to OKD
2. Create projects
3. Push image
4. Deploy app
5. Create secret & route

### [Lab 2: Follower Deployment with manual seed generation](02-manual_follower.md)
1. Create project 
2. Create serviceaccount
3. Push image
4. Deploy follower
5. Copy seed and config follower
6. Verify status

### [Lab 3: Follower Deployment with Seed-Fetcher](03-seed_fetcher.md)
1. Clean-up
2. Load Policy
3. Initialize CA
4. Enable authenicator
5. Create role
6. Load variables
7. Push images
8. Add Master certificate
9. Deploy followers

### [Lab 4: Securing OpenShift app with init container and summon](04-init_container.md)
1. Push image
2. Load policy for app
3. Prepare and load cert
4. Re-deploy app


### [Lab 5: Deploy cityapp with Secretless Broker](05-secretless.md)
1. Push image
2. Prepare and apply config
3. Re-deploy app

### [Extra Challenges](06-extra_challenges.md)

### Reference
 - [CyberArk documentation](https://docs.cyberark.com/)
