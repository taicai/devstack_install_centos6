# run this shell using stack user

# Start the installation
cd /opt/devstack
rm -f nohup.out; FORCE_PREREQ=true ./stack.sh | tee nohup.out

# Fix for "Permission denied" apache error
sudo chmod 755 /opt/stack/