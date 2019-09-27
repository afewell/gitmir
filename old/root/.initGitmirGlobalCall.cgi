#!/bin/bash
for line in $(cat /gitmir/gitmirhalist.json | jq -c '.[]')
do
    echo "entering the initGitmirGlobalCall do loop for line: $line" | tee -a /root/gitmirrun.log
    echo $line
    name=$(echo $line | jq -r '.name')
    echo "the value entered for name is: $name"
    fqdn=$(echo $line | jq -r '.fqdn')
    echo "the value entered for fqdn is: $fqdn"
    curl http://$fqdn/cgi-bin/initGitmirLocalCall.cgi
    wait
done