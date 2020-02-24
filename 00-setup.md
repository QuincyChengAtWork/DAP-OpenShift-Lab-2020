# Prerequisite: Environment Setup
This section describes how to setup the environment for this tutorial

## Setup CyberArk CorePAS based on CGD

This tutorial is based on 4 virtual machines (`DC`, `VAULT`, `COMP` & `CLIENT`) from  [CGD](https://ca-il-confluence.il.cyber-ark.com/display/gpse/CGD+-+20200101#/)
Note the lab was built with CGD-2020-0101-GA but should work with other versions or CorePas v11.1 as well.

Please refer to [confluence](https://ca-il-confluence.il.cyber-ark.com/pages/viewpage.action?pageId=285087892&preview=%2F285087892%2F297248443%2FCGD-Stand-Alone-Skytap-Demo-QuickStart_2019_1001.pdf) for detailed setup

## Setup 2 Extra VM (DAP Master & OKD)

We will setup 2 more VMs for this tutorial.  One as DAP Master instance and another one for executing OKD.

1. Download `040-OKD.7z` and `041-DAP-MASTER` from `/apj/Conjur-OpenShift-Workshop-20200221` folder in Smartfile.
2. Extract both files to your laptop (VM Host)
3. In the extracted folders, double click `040-OKD.vmx` & `041-DAP-MASTER.vmx` to import them to VMWare workstation.
4. Power on 4 VMs from CorePAS (`DC`, `VAULT`, `COMP` & `CLIENT`)
5. Login to `DC` VM
6. Start `DNS Manager` by clicking `DNS` shortcut on taskbar
7. Browse to `DNS > DC1 > Forward Lookup Zones > CyberArkDemo.com`
![dns manager](./images/00-dnsmgr.PNG)

7. Right-click `CyberArkDemo.com` and click `New Host (A or AAAA) to create the following DNS records

DNS record | IP Address
-----------|-----------
*.okd|10.0.1.40
docker03|10.0.1.41
master-dap|10.0.1.41
mysql01|10.0.1.41

![new host in dns](./images/00-dns.png)

8. Logoff `DC` VM
9. Start `DAP-MASTER` and `OKD` VMs

## Onboard MySQL Account to CorePAS

We are going to manage & secure a database secret.   Let's onboard the MySQL database credentials to CorePAS.  You can also refer to https://docs.cyberark.com/Product-Doc/OnlineHelp/PAS/Latest/en/Content/PASIMP/MySQLServerPlugin.htm

### Install MySQL server container 

1. Log in to `DAP-Master` VM as admin

2. Enable IP Forwarding and restart services
```bash
echo 1 > /proc/sys/net/ipv4/ip_forward
systemctl restart network
service docker restart
docker stop $(docker ps -a -q)
docker rm $(docker ps -a -q)
```

3. Create a MySQL container as our database server
```bash
mkdir db && cd db
wget https://downloads.mysql.com/docs/world.sql.gz
gunzip world.sql 
cd ..
docker run --name mysqldb -v /root/db:/docker-entrypoint-initdb.d \
     -e MYSQL_ROOT_PASSWORD=Cyberark1 \
     -e MYSQL_DATABASE=world \
     -e MYSQL_USER=cityapp \
     -e MYSQL_PASSWORD=Cyberark1 \
     -p "3306:3306" -d mysql:5.7.29 
```

:question: **Question: How will you verify it's up & running?**

### Install & Configure MySQL Driver
1. Log in to `COMP` VM as CYBERARKDEMO\administrator
2. Browse to https://dev.mysql.com/downloads/file/?id=492345
3. Click `No thanks, just start my download` to start downloading 32-bit MySQL ODBC driver
4. Double click the downloaded msi file to start installation
5. Click `Start` to search for `ODBC Data Source Administrator (32-bit)`
6. Browse to `Driver` tab and make sure MySQL are installed

![mysql driver](./images/00-mysql.png)

7.Logoff

### Create MySQL account in PVWA
1. Log in to `CLIENT` as `CYBERARKDEMO\Mike`
2. Browse to `https://components.cyberarkdemo.com/PasswordVault/v10/`
3. Select `Active Directory / LDAP` and login as `Mike`
4. Create a new safe called `appaccts` at `Policies > Access Control (Safe)` ([ref](https://docs.cyberark.com/Product-Doc/OnlineHelp/PAS/Latest/en/Content/PASIMP/Adding-and-Managing-Safes.htm)) 
5. Add `Vault Admins` and `CyberArk Vault Admins` with `Safe Management` rights
6. Activate `MySQL Server` platform at `Administration > Platform Management` ([ref](https://docs.cyberark.com/Product-Doc/OnlineHelp/PAS/Latest/en/Content/PASIMP/Activating-and-Deactivating-Platforms.htm))
7. Edit `MysQL Server` platform and update driver to `MySQL ODBC 8.0 Unicode Driver` in `ConnectionCommand` under `Target Account Platform > Automatic Password Management > Additional Policy Settings`

![mysql acc](./images/00-mysql_acc.png)

8. Create an account called `app-cityapp` at `Accounts > Account View`

Key|Value
---|-----
System Type|Database
Platform|MySQL
Safe|appaccts
Username|cityapp
Address|mysql01
Initial Password|Cyberark1
Port|3306
Database|world

9. Try verify and change the password

## Setup DAP Master

###	Load DAP image

1. Login to `DAP-Master` as `root`
2. Right-click the desktop and select `Open Terminal`

3. Conjur appliance (DAP) image has been loaded for you.
  To verify it, execute `docker images`

3. IF you want to load the image to docker again, you can save the compressed image file to `DAP-Master` and execute the following commands:
```bash
cd /root
docker load -i conjur-appliance_11.2.1.tar.gz
docker tag registry.tld/conjur-appliance:11.2.1 conjur-appliance:11.2.1
```

### Start DAP Master with signed certificate

1. Spin up the master container
```bash
docker run --name conjur-appliance -d --restart=always --security-opt seccomp:unconfined -p "443:443" -p "636:636" -p "5432:5432" -p "1999:1999" conjur-appliance:11.2.1
```

2. Copy the cert
```bash
docker cp /root/dap-certificate.tgz conjur-appliance:/tmp/dap-certificate.tgz
```

2.	Let's configure the DAP master instance and import the cert
```
docker exec -it conjur-appliance bash

evoke configure master --accept-eula -h master-dap.cyberarkdemo.com --master-altnames "master-dap.cyberarkdemo.com" -p Cyberark1 cyberark
cd /tmp
tar -zxvf dap-certificate.tgz
evoke ca import --root /tmp/dc1-ca.cer.pem
evoke ca import --key follower-dap.key.pem follower-dap.cer.pem
evoke ca import --key master-dap.key.pem --set master-dap.cer.pem
```	

3. Clean up the cert file and exit back to `DAP-MASTER` VM
```bash
rm dap-certificate.tgz *.pem
exit
```

4. Setup conjur CLI and load initial policy

```bash
alias conjur='docker run --rm -it --network host -v $HOME:/root -it cyberark/conjur-cli:5'
conjur init -u https://master-dap.cyberarkdemo.com
```
Key|Value
---|-----
Trust this certificate|yes
acccount name|cyberark
```
conjur authn login -u admin
conjur policy load root /root/policy/root.yaml
```

## Configure Vault Synchronizer

The CGD VM already have synchronizer installed on COMP. We will have to rerun the installer to point it to new master-dap ([ref](https://docs.cyberark.com/Product-Doc/OnlineHelp/AAM-DAP/Latest/en/Content/Conjur/cv_Synchronizer-lp.htm))

### Get the installation package

1. Log in to `COMP` as `Mike`
2. Copy or download `Conjur-Vault-Synchronizer` installation package.   It can be downloaded from SFE at `Root\Conjur\Vault Conjur Synchronizer\v11.2` in `CyberArk Versions` safe
3. Extract the installation package

### Reset synchronizer user password

4. Start  `PrivateArk` client and login as `administrator` 
5. Go to `Tools > Administrative Tools > Users and Groups`
6. Select `Sync_COMPONENTS` and click `Update...` on the right

7. Browse to `Authenication` tab 
8. Type `Cyberark1` to both `Password` and `Confirm` fields
   We will need to enter this password during synchronizer installation.
9. Click `OK` & `close`.    
10. Close `PrivateArk` Client 

### Re-install Synchronizer

11. Start` powershell`
12. Access to `Installation` folder under the extracted folder in step 3
13. Run installation script 

```powershell
.\V5SynchronizerInstallation.ps1
```

Key|Value
---|-----
target path|C:\Program Files\CyberArk\Synchronizer
username|admin
password|Cyberark1
hostname|master-dap.cyberarkdemo.com:443
account|cyberark
Synchronizer Vault User's username|Sync_COMPONENTS
Synchronizer Vault User's password|Cyberark1
Vault name|Vault
Vault address|10.0.1.10
Vauit port|1858

![ps](./images/00-resync.png)

13. After installation complete, obtain syncrhonizer Conjur API Key from the powershell console
```powershell
$credentials = Import-Clixml -Path synchronizerConjurHost.xml
$credentials.Username
$credentials.GetNetworkCredential().password
```
![ps](./images/00-sync_cred.png)

14. Login to PVWA as `Administrator` using `CyberArk` authenication

15. Search for `application conjur host` account
16. Change password of `Application-ConjurHost` object with api key value from previous command
17. Update `appliance_url` to point to new dap master `https://master-dap.cyberarkdemo.com`

![ps](./images/00-sync_acc.png)

18. Access to `Policies > Access Control (Safe)`
19. Select `appaccts` safe and click `Memebers`

20 . Add `LOBUser_appaccts` as safe member of our application safe. This gives synchronizer permission to sync objects from this safe.
![ps](./images/00-lob-user.png)

18. Click `Service` on taskbar

19. Start `CyberArk Vault-Conjur Synchronizer` service. If the service failed to start, check log at `c:\program files\CyberArk\Synchronizer\Logs` to troubleshoot

19.	After service start, verify that our objects are synchronized to Conjur Master

:question: **How to verify our objects are synchronized to Conjur Master?**
