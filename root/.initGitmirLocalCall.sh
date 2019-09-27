#!/bin/bash
TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
for addr in $(curl https://kubernetes.default.svc/api/v1/namespaces/gitmir/endpoints --silent --header "Authorization: Bearer $TOKEN" --insecure  | jq -rM ".items[0].subsets[].addresses[].ip")
do
    echo "entering the initGitmirLocallCall do loop for line: $addr" | tee -a /root/gitmirrun.log
    echo $addr
    curl http://$addr/cgi-bin/callGitmir.cgi
done