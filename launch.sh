#!/bin/bash

#Usage: ./launch.sh services/service.json

#Fail with no argument
if [ "$#" -ne 1 ]; then
        echo "Usage: ./launch.sh services/service.json"
        exit 1;
fi

curl -X POST -H "Content-Type: application/json" 192.168.56.101:8080/v2/apps -d@"$@"
