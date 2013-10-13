# move to163.com yum repo if necessarry
# ./centos6_163.sh

# Install some prereqs / utilities 
yum -y install mlocate vim openssl-devel euca2ools telnet Django14 git

# EPEL is required for all the additional packages required by OpenStack
rpm --import http://dl.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-6
rpm -Uvh http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm

# If you can't find a python-pip package the below can be used instead
easy_install pip
ln -s /usr/bin/pip /usr/bin/pip-python

# Horizon requires older version of Kombu. Not sure how old, but 1.0.4 seems to do the trick
# 'RabbitStrategy' object has no attribute 'connection_errors'
pip install kombu==1.0.4

# Clear out any IP table rules
iptables -F
iptables -X
iptables -t nat -F
iptables -t nat -X
iptables -t mangle -F
iptables -t mangle -X
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT
service iptables save

# Enable SSH keys on the server for easy remote access
# sed -i -r 's/^#(AllowAgentForwarding)/1/g' /etc/ssh/sshd_config
sed -i 's/^#AllowAgentForwarding/AllowAgentForwarding/' /etc/ssh/sshd_config
# Apply the above configuration change
service sshd restart

# Fix SSH SE-Linux permissions
restorecon -R -v /root/.ssh

# Make default policy permissive
setenforce permissive
sed -i 's/SELINUX=.*/SELINUX=permissive/' /etc/selinux/config

# Setup DevStack
cd /opt
git clone https://github.com/SV8/devstack.git
cd devstack

# ImproperlyConfigured: Error importing middleware horizon.middleware: "cannot import name SafeExceptionReporterFilter"
perl -p -i -e 's/^Django$/Django14/' files/rpms/horizon 
# pip install version 1.0.4 instead
perl -p -i -e 's/^(python-kombu)/#$1/' files/rpms/*

# Write a default localrc configuration 
cat<<__EOF__>localrc
FLOATING_RANGE=192.168.1.0/24
FIXED_RANGE=192.168.2.0/24
FIXED_NETWORK_SIZE=256
FLAT_INTERFACE=eth0
ADMIN_PASSWORD=openadmin
MYSQL_PASSWORD=openmysql
RABBIT_PASSWORD=openrabbit
SERVICE_PASSWORD=openservice
SERVICE_TOKEN=$(uuidgen)
__EOF__

# Switch to stack user
chmod +x /opt/devstack/tools/create-stack-user.sh
sh /opt/devstack/tools/create-stack-user.sh

# Fix for "Permission denied" error for /opt/devstack/
chown -R stack:stack /opt/devstack/
