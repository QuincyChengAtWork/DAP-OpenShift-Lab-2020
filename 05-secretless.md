# Lab 5: Deploy cityapp with Secretless Broker
Push image
Prepare and apply config
Re-deploy app


1. Log in to `DAP-MASTER` as `root`
2.	Push secretless broker image to openshift registry.

```
docker tag cyberark/secretless-broker:latest docker-registry-default.apps.okd.cyberarkdemo.com/cityapp/secretless-broker
docker push  docker-registry-default.apps.okd.cyberarkdemo.com/cityapp/secretless-broker
```

4.	These should have been done in the previous lab. Make sure all are in place. 
  - Follower certificate in configmap
  - Conjur policy for cityapp-secretless
  - Openshift clusterrolebinding to allow follower to validate Pods in cityapp namespace

5.	Make sure we are using the correct namespace

```
oc project cityapp
```

7.	Review and make necessary changes Secretless configuration file `secretless.yaml` and load it as a new configmap
```
cd /root/lab5_secretless
oc create configmap cityapp-secretless-config --from-file=secretless.yaml
```
:bulb: Make sure you have updated it!

8.	Review `cityapp-secretless.yaml` deployment file and modify it with proper value for your environment. 
    Apply the file to deploy `cityapp` with secretless-broker.
```
oc apply -f cityapp-secretless.yaml
```

9.	Test access to this application. Note username and password seen by the application container.

## Extra Tech Challengs
- You can perform additional test by rotating mysql password using CPM and observe how each application deployment react. 
- Another good exercise is to create dual account for cityapp. (Note that cityappA and cityappB accounts are already provisioned on MySQL)
