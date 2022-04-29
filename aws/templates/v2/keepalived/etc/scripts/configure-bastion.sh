mv /tmp/id_rsa.pub /home/ec2-user/.ssh/
mv /tmp/id_rsa.secret /home/ec2-user/.ssh/id_rsa
chmod 600 /home/ec2-user/.ssh/id_rsa
chmod 644 /home/ec2-user/.ssh/id_rsa.pub