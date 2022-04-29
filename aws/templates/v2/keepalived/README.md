#!/bin/bash

AWS_INSTANCE_ID=$(wget -q -O - http://instance-data/latest/meta-data/instance-id)
AWS_NIC=keepalived-01-failover-01
AWS_NIC_ID=$(aws ec2 describe-network-interfaces --filter "Name=tag:Name,Values=$AWS_NIC" --query "NetworkInterfaces[].NetworkInterfaceId" --output text)

if [ -z "$AWS_NIC_ID" ]
then
        logger -t failover-aws Could not find network interface with name '$AWS_NIC'
        exit 1
fi

AWS_ATTACHMENT_ID=$(aws ec2 describe-network-interfaces --network-interface-id $AWS_NIC_ID --query "NetworkInterfaces[].Attachment.AttachmentId" --output text)
AWS_REGION=us-east-1
LOG=/tmp/failover-aws

logger -t failover-aws Updating AWS network interface $AWS_NIC_ID
logger -t failover-aws Instance id: $AWS_INSTANCE_ID
logger -t failover-aws NIC id: $AWS_NIC_ID
logger -t failover-aws Attachment id: $AWS_ATTACHMENT_ID
if [ -n "$AWS_ATTACHMENT_ID" ]
then
        /usr/local/bin/aws ec2 detach-network-interface --attachment-id $AWS_ATTACHMENT_ID
        while [ "$AWS_NIC_STATE" != "available" ]
        do
                sleep 2
                AWS_NIC_STATE=$(aws ec2 describe-network-interfaces --network-interface-id $AWS_NIC_ID --query "NetworkInterfaces[].Status" --output text)
                logger -t failover-aws $AWS_NIC_ID status is currently: $AWS_NIC_STATE
        done
else
        logger -t failover-aws $AWS_NIC_ID is not currently attached\; attaching to self
fi
/usr/local/bin/aws ec2 attach-network-interface --network-interface-id $AWS_NIC_ID --instance-id $AWS_INSTANCE_ID --device-index 1