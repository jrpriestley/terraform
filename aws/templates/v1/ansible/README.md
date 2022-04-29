This template will deploy an Ansible implementation. It is a work in progress.

The following steps will be performed:

- Deploy VPC and networking
- Deploy Ansible host (x1) and clients (x2)
- Build Ansible inventory file using the deployed clients (will be updated and redeployed if the client list changes)
- Ping the clients via Ansible