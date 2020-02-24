# Lab 2: Follower Deployment with manual seed generation

Now you should be familar with OpenShift.   Let's deploy DAP followers on OpenShift.

First, we will deploy followers manually.



## Create project & serviceaccount

1. Log in to `DAP-MASTER` VM as `root`

2. Right click desktop and select `Open Terminal`

3. Access lab2 folder
```
cd /root/lab2_follower_deployment
```

4. Create dap project for follower deployment. Grant anyui scc to to run as 
```
oc new-project dap
```

5. Create service account for conjur deployment and grant it with anyuid scc. This is required for deployment in OpenShift.

```
oc create serviceaccount conjur-cluster -n dap
oc adm policy add-scc-to-user anyuid "system:serviceaccount:dap:conjur-cluster"
```

> :bulb:	Note that the new decomposed deployment option is now available if this scc cannot be granted. 
> However, it is not part of this lab.


## Push conjur image to OpenShift registry
```
docker tag conjur-appliance:11.2.1 docker-registry-default.apps.okd.cyberarkdemo.com/dap/conjur-appliance:11.2.1
docker push docker-registry-default.apps.okd.cyberarkdemo.com/dap/conjur-appliance:11.2.1
```
We will deploy follower from deploymentconfig file. 
Review `follower-dap.yaml` file and make any necessary changes before apply the file.

```
cat follower-dap.yaml
```
In our setup, we will using `dap` namespace and will use `okd` as `authenticator_id`
```
oc apply -f follower-dap.yaml
```

# To check log
```
oc get pods
oc logs [pod-name]
```

9.	Generate follower seed on DAP master container. As we are using signed certificate that was previously imported, make sure you enter the exact hostname for follower.
```
docker exec conjur-appliance evoke seed follower follower.dap.svc.cluster.local > follower-seed.tar
```

10.	Copy seed file to follower pod and trigger evoke to configure follower
```
oc cp follower-seed.tar [pod-name]:/tmp
oc exec [pod-name] evoke unpack seed /tmp/follower-seed.tar
oc exec [pod-name] evoke configure follower
```

##	Verify status of the follower
```
oc exec [pod-name] -- curl -k https://localhost/health
oc exec [pod-name] -- curl -k https://localhost/info
```

## Extra Tech Challenages
- Apart from `oc` command, how can we verify the follower status?
- What happen if Pod restart or OpenShift reschedule this on another node? 
- What will happen if the pod scale up & down?
