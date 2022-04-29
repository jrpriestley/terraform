This template creates a VPC and optional Internet Gateway.

The following resources are added using this template:

- VPC
- Internet Gateway

Read/edit the 'main.tf' accordingly to specify your configuration and add AWS credentials to new file 'aws.credentials' accordingly, e.g.,:

[default]
aws_access_key_id = <access-key>
aws_secret_access_key = <secret-access-key>