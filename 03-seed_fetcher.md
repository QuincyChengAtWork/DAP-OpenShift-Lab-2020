# Lab 3: Follower Deployment with Seed-Fetcher

## Clean-up
## Load Policy
Initialize CA
Enable authenicator
Create role
Load variables
Push images
Add Master certificate
Deploy followers


We can deployment follower with seed-fetcher which automatically authenticate and retrieve seed on Pod start up. This allow self-healing and auto scaling of follower pods.

## Clean up
First, let's remove deployment from Lab 2
```
oc delete deploymentconfig follower
oc delete svc follower
```

## Load Conjur Policies

1.	Review below conjur policy files and make necessary changes before load it to conjur 
```
conjur policy load root /root/policy/authn-k8s-cluster.yaml
```

2.	Initialize internal CA that will be used for K8S Authenticator 
```
docker exec conjur-appliance chpst -u conjur conjur-plugin-service possum rake authn_k8s:ca_init["conjur/authn-k8s/okd"]
```

3. Access Conjur UI and verify that conjur/authn-k8s/okd/ca/cert and key have value not blank

###	Enable K8S Authetnication on Master node
1. Add `CONJUR_AUTHENTICATORS="authn,authn-k8s/okd"` to `/opt/conjur/etc/conjur.conf` in Master container
2. Restart container to `/opt/conjur/etc/conjur.conf` in Master container 
3. Restart conjur service to apply this change.
``` 
docker exec -it conjur-appliance vi /opt/conjur/etc/conjur.conf
docker exec conjur-appliance sv restart conjur
```

4.	Verify that okd authenticator is now enabled on Master
```
curl -k https://master-dap.cyberarkdemo.com/info
```

###	Create cluster role and role binding for conjur-cluster service account. 

1. Review `conjur-authenticator-role.yaml` and `conjur-authenticator-role-binding.yaml` and use oc cli to apply it.

```
oc apply -f conjur-authenticator-role.yaml
oc apply -f conjur-authenticator-role-binding.yaml
```
__**OR**__

Instead of applying rolebinding to individual namespace. We may apply it at cluster level. 
This will allow conjur-cluster service account to check property and push k8s-authn certificate to all projects (i.e. namespace).

```
oc apply -f conjur-authenticator-clusterrole-binding.yaml
```

2. Configure OpenShift API Detail in Conjur
```
TOKEN_SECRET_NAME="$(oc get secrets -n dap \
| grep 'conjur.*service-account-token' \
| head -n1 \
| awk '{print $1}')"

CA_CERT="$(oc get secret -n dap $TOKEN_SECRET_NAME -o json \
| jq -r '.data["ca.crt"]' \
| base64 --decode)"

SERVICE_ACCOUNT_TOKEN="$(oc get secret -n dap $TOKEN_SECRET_NAME -o json \
| jq -r .data.token \
| base64 --decode)"

API_URL="$(oc config view --minify -o json \
| jq -r '.clusters[0].cluster.server')"
```

3. Verify the vaules in the environmental variables
```
echo $TOKEN_SECRET_NAME
echo $CA_CERT
echo $SERVICE_ACCOUNT_TOKEN
echo $API_URL
```

4. Load them to Conjur as variables
```
conjur variable values add conjur/authn-k8s/okd/kubernetes/ca-cert "$CA_CERT"
conjur variable values add conjur/authn-k8s/okd/kubernetes/service-account-token "$SERVICE_ACCOUNT_TOKEN"
conjur variable values add conjur/authn-k8s/okd/kubernetes/api-url "$API_URL"
```

5. Verify that the OpenShift API detail are loaded correctly to these conjur variables

6.	Push dap-seedfetcher image to OpenShift integrated registry under dap project 
```
docker tag cyberark/dap-seedfetcher:latest docker-registry-default.apps.okd.cyberarkdemo.com/dap/dap-seedfetcher
docker push docker-registry-default.apps.okd.cyberarkdemo.com/dap/dap-seedfetcher
```

7.	Add Conjur Master certificate to config map. This will be used by seedfetcher to validate Conjur Master.

```
openssl s_client -showcerts -connect master-dap.cyberarkdemo.com:443 -servername master-dap.cyberarkdemo.com </dev/null | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > master-certificate.pem	
oc create configmap master-certificate --from-file=ssl-certificate=<(cat /root/master-cyberark.pem)
```
This is actually the same certificate that conjur-cli retrieved during cli initialization.

8.	Review and make necessary changes to follower-dap-seedfetcher.yaml deployment yaml. Then use oc command to apply. 
```
oc apply -f follower-dap-with-seedfetcher.yaml
```

9.	Verify the follower Pods started properly. 
Follower should now be exposed via route `https://follower-dap.apps.okd.cyberarkdemo.com` 

## Extra Tech Challeng
-	Try scale up follower pods to 2 from the deployment screen and verify the logs from OpenShift & Master container
-	Try scale up follower pods to 3 from the deployment screen and verify the logs from OpenShift & Master container
-	Try scale down follower pods back to 2 from the deployment screen and verify the logs from OpenShift & Master container

