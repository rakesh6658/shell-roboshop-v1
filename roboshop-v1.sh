#!/bin/bash

image_id="ami-0055977a6e828a4f4"
instance_type="t3.micro"
domain_name="joindevops.online"
Hosted_zone_id="Z01170992B3XLBKODT7HI"

for instance in $@
do
instance_id=$(aws ec2 run-instances \
    --image-id "${image_id}" \
    --instance-type "${instance_type}" \
    --security-groups roboshop-common "roboshop-${instance}" \
     --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=roboshop-${instance}}]" \
    --query 'Instances[0].InstanceId' \
    --output text)

echo "instance_id=$instance_id"

if [ $instance != "frontend" ]; then
  IP=$(aws ec2 describe-instances \
    --instance-ids "${instance_id}" \
    --query 'Reservations[*].Instances[*].PrivateIpAddress' \
    --output text)
else
IP=$(aws ec2 describe-instances \
    --instance-ids "${instance_id}" \
    --query 'Reservations[*].Instances[*].PublicIpAddress' \
    --output text)
fi
 echo "$instance ip address $IP"

aws route53 change-resource-record-sets \
    --hosted-zone-id "${Hosted_zone_id}" \
    --change-batch '{
      "Changes": [{
        "Action": "UPSERT",
        "ResourceRecordSet": {
          "Name": "${instance}.${domain_name}",
          "Type": "A",
          "TTL": 1,
          "ResourceRecords": [
            {"Value": "${IP}"}
          ]
        }
      }]
    }'
echo "updated record name : "${instance}.${domain_name}""
done
