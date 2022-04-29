chmod 600 /home/ec2-user/.ssh/id_rsa
sudo yum update -y
sudo yum install -y httpd httpd-tools mod_ssl
sudo systemctl enable httpd
sudo systemctl start httpd
sudo amazon-linux-extras enable php7.4
sudo yum clean metadata 
sudo yum install -y php php-common php-pear 
sudo yum install -y php-{cgi,curl,mbstring,gd,mysqlnd,gettext,json,xml,fpm,intl,zip}
echo "<?php phpinfo(); ?>" | sudo tee /var/www/html/info.php
sudo systemctl restart httpd