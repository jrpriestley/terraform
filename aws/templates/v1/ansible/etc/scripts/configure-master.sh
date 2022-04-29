chmod 600 /home/ec2-user/.ssh/id_rsa
sudo yum update -y
sudo amazon-linux-extras install ansible2 -y
sudo sed '/host_key_checking/s/^#//' -i /etc/ansible/ansible.cfg