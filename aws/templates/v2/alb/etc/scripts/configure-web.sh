chmod 600 /home/ec2-user/.ssh/id_rsa
sudo yum update -y
sudo yum install -y httpd httpd-tools mod_ssl
sudo systemctl enable httpd
sudo systemctl start httpd