#!/bin/bash
# EC2 user data: Apache + CodeDeploy agent (us-east-1). Change the region in the URL if you use another region.
yum update -y
yum install -y httpd
systemctl start httpd
systemctl enable httpd
yum install -y ruby wget
cd /home/ec2-user
wget https://aws-codedeploy-us-east-1.s3.us-east-1.amazonaws.com/latest/install
chmod +x ./install
./install auto
systemctl start codedeploy-agent
systemctl enable codedeploy-agent
