#!/bin/bash

# if the Centos VBOX isnt here then pull it down and extract
if [ ! -f centos71.box ]; then
  wget https://github.com/geekbass/centos7-vbox/raw/master/centos71.box.zip
  unzip centos71.box.zip
  rm -rf centos71.box.zip
fi

# Build Mesos1
vagrant up

# Build Mesos2
cd mesos2/
vagrant up
cd ..

echo "Build of Cluster is Complete...."
echo ""
echo "List of Service URLs...."
echo "Open the following in your Browser...."
echo "Mesos Master: http://192.168.56.101:5050 "
echo "Marathon: http://192.168.56.101:8080"
echo "Aurora: "
echo "Kubernets: "
echo "Jenkins: http://192.168.56.101:9000"
echo ""
echo "Other service URLs of note...."
echo "Mesos Slaves: "
echo "Zookeeper: "
echo ""
echo "Enjoy!!!"
