#!/bin/bash
yum clean all
yum update -y
yum groupinstall -y "Development Tools"

#Set the hostname
echo "mesos1" > /etc/hostname
hostnamectl set-hostname mesos1
echo "192.168.56.101    mesos1 jenkins  marathon  aurora  zookeeper1  docker1" >> /etc/hosts
echo "192.168.56.102    mesos2  docker2" >> /etc/hosts


#Add the correct Repos
echo "###################"
echo "Adding Mesos Repos"
echo "###################"
rpm -ivh http://repos.mesosphere.com/el/7/noarch/RPMS/mesosphere-el-repo-7-1.noarch.rpm
yum install -y epel-release
#cp -r /home/vagrant/sync/mesos1/mesos-configs/wandisco-svn.repo /etc/yum.repos.d/

#Install base packages
echo "#########################"
echo "Installing base packages"
echo "#########################"
yum install -y python-pip redhat-lsb tar vim-common vim-enhanced bind-utils python-dev java-1.7.0-openjdk java-1.7.0-openjdk-devel java-1.7.0-openjdk-headless maven nginx curl git wget docker apache-maven zlib-devel libcurl-devel openssl-devel cyrus-sasl-devel cyrus-sasl-md5 apr-devel apr-util-devel


#Turn off Selinux and Firewalld
systemctl stop firewalld && systemctl disable firewalld
perl -p -i -e 's/enforcing/disabled/g' /etc/selinux/config

#Turn off IPv6
echo "net.ipv6.conf.all.disable_ipv6 = 1" >> /etc/systctl.conf
echo "net.ipv6.conf.default.disable_ipv6 = 1" >> /etc/sysctl.conf
echo "net.ipv6.conf.lo.disable_ipv6 = 1" >> /etc/sysctl.conf
sysctl -p

#Install Mesos/Slave
echo "#################"
echo "Installing Mesos"
echo "#################"
#wget http://downloads.mesosphere.io/master/centos/7/mesos-0.22.2-0.2.62.centos701406.x86_64.rpm
#rpm -ivh mesos-0.22.2-0.2.62.centos701406.x86_64.rpm
#rm mesos-0.22.2-0.2.62.centos701406.x86_64.rpm
yum install -y mesos

#Install Zookeeper
echo "#####################"
echo "Installing Zookeeper"
echo "#####################"
yum install -y  mesosphere-zookeeper

#Configure Mesos Master/Zookeeper/Slave1
echo "##########################################"
echo "Configuring Mesos Master/Zookeeper/Slave1"
echo "##########################################"
cp -r /home/vagrant/sync/mesos1/mesos-configs/zookeeper/myid /var/lib/zookeeper/myid
cp -r /home/vagrant/sync/mesos1/mesos-configs/zookeeper/zoo.cfg /etc/zookeeper/conf/zoo.cfg

#Configure Mesos Master
cp -r /home/vagrant/sync/mesos1/mesos-configs/mesos/zk /etc/mesos/zk
cp -r /home/vagrant/sync/mesos1/mesos-configs/mesos-master/ip /etc/mesos-master/ip
cp -r /home/vagrant/sync/mesos1/mesos-configs/mesos-master/cluster /etc/mesos-master/cluster


#Configure Mesos Slave
cp -r /home/vagrant/sync/mesos1/mesos-configs/mesos-slave/containerizers /etc/mesos-slave/containerizers
cp -r /home/vagrant/sync/mesos1/mesos-configs/mesos-slave/hostname /etc/mesos-slave/hostname
cp -r /home/vagrant/sync/mesos1/mesos-configs/mesos-slave/ip /etc/mesos-slave/ip
cp -r /home/vagrant/sync/mesos1/mesos-configs/mesos-slave/attributes /etc/mesos-slave/attributes
cp -r /home/vagrant/sync/mesos1/mesos-configs/mesos-slave/recover /etc/mesos-slave/recover
cp -r /home/vagrant/sync/mesos1/mesos-configs/mesos-slave/docker_remove_delay /etc/mesos-slave/docker_remove_delay

#Install Marathon
echo "####################"
echo "Installing Marathon"
echo "####################"
yum install -y marathon
cp -r /home/vagrant/sync/mesos1/frameworks/marathon/haproxy-marathon-bridge.sh /opt/
/opt/haproxy-marathon-bridge.sh install_haproxy_system localhost:8080

#Marahon requires Java8 so set it!
JAVA=`ls /usr/lib/jvm/java-1.8*/jre/bin/java`
alternatives --set java $JAVA

#Install Jenkins
echo "###################"
echo "Installing Jenkins"
echo "###################"
wget -O /etc/yum.repos.d/jenkins.repo http://pkg.jenkins-ci.org/redhat/jenkins.repo
rpm --import https://jenkins-ci.org/redhat/jenkins-ci.org.key
mkdir -pv /var/lib/jenkins/plugins
cp -r /home/vagrant/sync/mesos1/frameworks/jenkins/mesos.hpi /var/lib/jenkins/plugins/mesos.hpi
yum install -y jenkins

#Jenkins configuration
cp -r /home/vagrant/sync/mesos1/frameworks/jenkins/jenkins /etc/sysconfig/jenkins
cp -r /home/vagrant/sync/mesos1/frameworks/jenkins/config.xml /var/lib/jenkins/
cp -r /home/vagrant/sync/mesos1/frameworks/jenkins/jenkins.model.JenkinsLocationConfiguration.xml /var/lib/jenkins
chown -R jenkins:jenkins /var/lib/jenkins/plugins

echo "#########################"
echo "Configure Mesos CLI"
echo "#########################"
ORIG_MESOS_CLI=`which mesos`
rm -rf $ORIG_MESOS_CLI
pip install --upgrade pip
pip uninstall mesos.cli
pip install mesos.cli
mesos config master zk://localhost:2181/mesos

#Start and enable all Services
systemctl enable docker
systemctl enable haproxy
systemctl enable zookeeper
systemctl enable marathon


echo "####################################"
echo "Initial Pull of Mesos-Dind Image"
echo "####################################"
systemctl start docker
docker pull wbassler23/mesos-docker-demo:latest

echo "##########################################"
echo "Including Spotify's Docker Cleanup Script"
echo "##########################################"
cp -r /home/vagrant/sync/docker-gc /opt/

echo "#########################"
echo "Complete!!! Rebooting!!!"
echo "#########################"
reboot
