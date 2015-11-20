#!/bin/bash
yum clean all
yum update -y
yum groupinstall -y "Development Tools"

#Set the hostname
echo "mesos2" > /etc/hostname
hostnamectl set-hostname mesos2
echo "192.168.56.101    mesos1 jenkins  marathon  aurora  zookeeper1  docker1" >> /etc/hosts
echo "192.168.56.102    mesos2  docker2" >> /etc/hosts


#Add the correct Repos
echo "######################"
echo "Adding correct Repos"
echo "######################"
rpm -Uvh http://repos.mesosphere.com/el/7/noarch/RPMS/mesosphere-el-repo-7-1.noarch.rpm
yum install -y epel-release
#cp -r /home/vagrant/sync/mesos-configs/wandisco-svn.repo /etc/yum.repos.d/

#Install base packages
echo "#########################"
echo "Installing base packages"
echo "##########################"
yum install -y redhat-lsb python-pip tar vim-common vim-enhanced bind-utils python-dev java-1.7.0-openjdk java-1.7.0-openjdk-devel java-1.7.0-openjdk-headless maven nginx curl git wget docker

#Turn off Selinux and Firewalld
systemctl stop firewalld && systemctl disable firewalld
perl -p -i -e 's/enforcing/disabled/g' /etc/selinux/config

#Turn off IPv6
echo "net.ipv6.conf.all.disable_ipv6 = 1" >> /etc/systctl.conf
echo "net.ipv6.conf.default.disable_ipv6 = 1" >> /etc/sysctl.conf
echo "net.ipv6.conf.lo.disable_ipv6 = 1" >> /etc/sysctl.conf
sysctl -p

#Install Mesos/Slave
echo "##################"
echo "Installing Mesos"
echo "##################"
#wget -q http://downloads.mesosphere.io/master/centos/7/mesos-0.22.2-0.2.62.centos701406.x86_64.rpm
#rpm -ivh mesos-0.22.2-0.2.62.centos701406.x86_64.rpm
#rm mesos-0.22.2-0.2.62.centos701406.x86_64.rpm
yum install -y mesos

#Zookeeper Config
cp -r /home/vagrant/sync/mesos-configs/mesos/zk /etc/mesos/zk

#Configure Mesos Slave
cp -r /home/vagrant/sync/mesos-configs/mesos-slave/containerizers /etc/mesos-slave/containerizers
cp -r /home/vagrant/sync/mesos-configs/mesos-slave/hostname /etc/mesos-slave/hostname
cp -r /home/vagrant/sync/mesos-configs/mesos-slave/ip /etc/mesos-slave/ip
cp -r /home/vagrant/sync/mesos-configs/mesos-slave/attributes /etc/mesos-slave/attributes
cp -r /home/vagrant/sync/mesos-configs/mesos-slave/recover /etc/mesos-slave/recover
cp -r /home/vagrant/sync/mesos-configs/mesos-slave/docker_remove_delay /etc/mesos-slave/docker_remove_delay

#Jenkins configuration
groupadd jenkins && useradd -g jenkins jenkins

#Start and enable all Services
systemctl enable docker
systemctl disable mesos-master
systemctl enable mesos-slave

echo "####################################"
echo "Initial Pull of Mesos-Dind Image"
echo "####################################"
systemctl start docker
docker pull wbassler23/mesos-docker-demo:latest

echo "#################################################################"
echo "Including Spotify's Docker Cleanup Script (run: /opt/docker-gc)"
echo "#################################################################"
cp -r /home/vagrant/sync/docker-gc /opt/

echo "##########################"
echo "Complete!!! Rebooting!!!"
echo "##########################"
reboot
