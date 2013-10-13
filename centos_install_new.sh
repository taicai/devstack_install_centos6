# execute this script with stack user

# Install some prereqs / utilities 
sudo yum -y install mlocate vim openssl-devel euca2ools telnet Django14 git
# EPEL is required for all the additional packages required by OpenStack
sudo rpm --import http://dl.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-6
sudo rpm -Uvh http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm

# If you can't find a python-pip package the below can be used instead
sudo easy_install pip
sudo ln -s /usr/bin/pip /usr/bin/pip-python

# Horizon requires older version of Kombu. Not sure how old, but 1.0.4 seems to do the trick
# 'RabbitStrategy' object has no attribute 'connection_errors'
sudo pip install kombu==1.0.4

# Clear out any IP table rules
sudo iptables -F
sudo iptables -X
sudo iptables -t nat -F
sudo iptables -t nat -X
sudo iptables -t mangle -F
sudo iptables -t mangle -X
sudo iptables -P INPUT ACCEPT
sudo iptables -P FORWARD ACCEPT
sudo iptables -P OUTPUT ACCEPT
sudo service iptables save

# Enable SSH keys on the server for easy remote access
# sed -i -r 's/^#(AllowAgentForwarding)/1/g' /etc/ssh/sshd_config
sudo sed -i 's/^#AllowAgentForwarding/AllowAgentForwarding/' /etc/ssh/sshd_config
# Apply the above configuration change
sudo service sshd restart

# Fix SSH SE-Linux permissions
sudo restorecon -R -v /root/.ssh

# Make default policy permissive
sudo setenforce permissive
sudo sed -i 's/SELINUX=.*/SELINUX=permissive/' /etc/selinux/config

# Setup DevStack
cd /opt
sudo git clone https://github.com/SV8/devstack.git
cd devstack

# ImproperlyConfigured: Error importing middleware horizon.middleware: "cannot import name SafeExceptionReporterFilter"
sudo perl -p -i -e 's/^Django$/Django14/' files/rpms/horizon 
# pip install version 1.0.4 instead
sudo perl -p -i -e 's/^(python-kombu)/#$1/' files/rpms/*

# Write a default localrc configuration 
sudo cat<<__EOF__>localrc
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

# Start the installation
cd /opt/devstack
rm -f nohup.out; FORCE_PREREQ=true ./stack.sh | tee nohup.out

# Fix for "Permission denied" apache error
sudo chmod 755 /opt/stack/
