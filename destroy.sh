#!/usr/bin/env bash

# Remove mesos2
cd mesos2/
vagrant destroy --force
vagrant box remove mesos2

#Remove mesos1
cd ..
vagrant destroy --force
vagrant box remove mesos1
