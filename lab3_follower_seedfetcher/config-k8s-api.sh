#== Obtain K8S API detail and load to Conjur
# This should be applied after creating Kubernetes service account

CONJUR_NAMESPACE_NAME=dap
AUTHENTICATOR_ID=okd

TOKEN_SECRET_NAME="$(oc get secrets -n $CONJUR_NAMESPACE_NAME \
    | grep 'conjur.*service-account-token' \
    | head -n1 \
    | awk '{print $1}')"

CA_CERT="$(oc get secret -n $CONJUR_NAMESPACE_NAME $TOKEN_SECRET_NAME -o json \
      | jq -r '.data["ca.crt"]' \
      | base64 --decode)"

SERVICE_ACCOUNT_TOKEN="$(oc get secret -n $CONJUR_NAMESPACE_NAME $TOKEN_SECRET_NAME -o json \
      | jq -r .data.token \
      | base64 --decode)"

API_URL="$(oc config view --minify -o json \
      | jq -r '.clusters[0].cluster.server')"

echo "TOKEN=$TOKEN_SECRET_NAME"
echo "SERVICE_ACCOUNT_TOKEN=$SERVICE_ACCOUNT_TOKEN"

echo "Logged In"
docker run --rm --network host -v $HOME:/root -it cyberark/conjur-cli:5 variable values add conjur/authn-k8s/$AUTHENTICATOR_ID/kubernetes/ca-cert "$CA_CERT"

echo "Load CA Cert"
docker run --rm --network host -v $HOME:/root -it cyberark/conjur-cli:5 variable values add conjur/authn-k8s/$AUTHENTICATOR_ID/kubernetes/service-account-token "$SERVICE_ACCOUNT_TOKEN"

echo "Load SA Token"
docker run --rm --network host -v $HOME:/root -it cyberark/conjur-cli:5 variable values add conjur/authn-k8s/$AUTHENTICATOR_ID/kubernetes/api-url "$API_URL"

