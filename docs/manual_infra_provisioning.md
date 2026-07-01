# NotesApp Monolithic Infrastructure (AWS CLI)

This document describes how to provision the infrastructure required to run the **NotesApp Monolithic Backend** on AWS using only the AWS CLI.

The infrastructure provisions:

- VPC
- Subnet
- Internet Gateway
- Route Table
- Security Group
- EC2 Instance
- SSH access
- Public networking

The EC2 instance will host the **NotesApp monolithic service running on port `3000`**.

---

# Architecture

NotesApp runs as a **monolithic application** deployed on a single EC2 instance.

Client → Internet → Internet Gateway → VPC → Subnet → EC2 → NotesApp (port 3000)

Open ports:

| Port | Purpose |
|-----|------|
| 22 | SSH access |
| 80 | HTTP |
| 3000 | NotesApp backend |

---

# Prerequisites

Install AWS CLI

```bash
sudo apt install awscli
````

Configure credentials

```bash
aws configure
```

Verify access

```bash
aws sts get-caller-identity
```

---

# Infrastructure Provisioning

---

# 1 Set AWS Region

```bash
export AWS_REGION=us-east-1
```

---

# 2 Create NotesApp VPC

```bash
VPC_ID=$(aws ec2 create-vpc \
--cidr-block 10.0.0.0/16 \
--tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=notesapp-vpc}]' \
--query 'Vpc.VpcId' \
--output text)

echo $VPC_ID
```

---

# 3 Enable DNS Support

```bash
aws ec2 modify-vpc-attribute \
--vpc-id $VPC_ID \
--enable-dns-support
```

---

# 4 Enable DNS Hostnames

```bash
aws ec2 modify-vpc-attribute \
--vpc-id $VPC_ID \
--enable-dns-hostnames
```

---

# 5 Create NotesApp Subnet

```bash
SUBNET_ID=$(aws ec2 create-subnet \
--vpc-id $VPC_ID \
--cidr-block 10.0.1.0/24 \
--tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=notesapp-subnet}]' \
--query 'Subnet.SubnetId' \
--output text)

echo $SUBNET_ID
```

---

# 6 Create Internet Gateway

```bash
IGW_ID=$(aws ec2 create-internet-gateway \
--tag-specifications 'ResourceType=internet-gateway,Tags=[{Key=Name,Value=notesapp-igw}]' \
--query 'InternetGateway.InternetGatewayId' \
--output text)

echo $IGW_ID
```

---

# 7 Attach Internet Gateway

```bash
aws ec2 attach-internet-gateway \
--internet-gateway-id $IGW_ID \
--vpc-id $VPC_ID
```

---

# 8 Create Route Table

```bash
RT_ID=$(aws ec2 create-route-table \
--vpc-id $VPC_ID \
--tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=notesapp-rt}]' \
--query 'RouteTable.RouteTableId' \
--output text)

echo $RT_ID
```

---

# 9 Create Internet Route

```bash
aws ec2 create-route \
--route-table-id $RT_ID \
--destination-cidr-block 0.0.0.0/0 \
--gateway-id $IGW_ID
```

---

# 10 Associate Route Table with Subnet

```bash
aws ec2 associate-route-table \
--subnet-id $SUBNET_ID \
--route-table-id $RT_ID
```

---

# 11 Enable Public IP Assignment

```bash
aws ec2 modify-subnet-attribute \
--subnet-id $SUBNET_ID \
--map-public-ip-on-launch
```

---

# 12 Create NotesApp Key Pair

```bash
KEY_NAME=notesapp-key

aws ec2 create-key-pair \
--key-name $KEY_NAME \
--query 'KeyMaterial' \
--output text > $KEY_NAME.pem

chmod 400 $KEY_NAME.pem
```

---

# 13 Create NotesApp Security Group

```bash
SG_ID=$(aws ec2 create-security-group \
--group-name notesapp-sg \
--description "Security group for NotesApp" \
--vpc-id $VPC_ID \
--query 'GroupId' \
--output text)

echo $SG_ID
```

---

# 14 Allow SSH Access

```bash
aws ec2 authorize-security-group-ingress \
--group-id $SG_ID \
--protocol tcp \
--port 22 \
--cidr 0.0.0.0/0
```

---

# 15 Allow HTTP

```bash
aws ec2 authorize-security-group-ingress \
--group-id $SG_ID \
--protocol tcp \
--port 80 \
--cidr 0.0.0.0/0
```

---

# 16 Allow NotesApp Port

```bash
aws ec2 authorize-security-group-ingress \
--group-id $SG_ID \
--protocol tcp \
--port 3000 \
--cidr 0.0.0.0/0
```

---

# 17 Fetch Latest Amazon Linux AMI

```bash
AMI_ID=$(aws ec2 describe-images \
--owners amazon \
--filters "Name=name,Values=amzn2-ami-hvm-*-x86_64-gp2" \
--query 'Images | sort_by(@,&CreationDate)[-1].ImageId' \
--output text)

echo $AMI_ID
```

---

# 18 Launch NotesApp EC2 Instance

```bash
INSTANCE_ID=$(aws ec2 run-instances \
--image-id $AMI_ID \
--instance-type t2.micro \
--key-name $KEY_NAME \
--subnet-id $SUBNET_ID \
--security-group-ids $SG_ID \
--associate-public-ip-address \
--tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=notesapp-server}]' \
--query 'Instances[0].InstanceId' \
--output text)

echo $INSTANCE_ID
```

---

# 19 Wait For Instance To Run

```bash
aws ec2 wait instance-running \
--instance-ids $INSTANCE_ID
```

---

# 20 Retrieve Public IP

```bash
PUBLIC_IP=$(aws ec2 describe-instances \
--instance-ids $INSTANCE_ID \
--query 'Reservations[0].Instances[0].PublicIpAddress' \
--output text)

echo $PUBLIC_IP
```

---

# 21 Wait Until Instance Passes Health Checks

```bash
aws ec2 wait instance-status-ok \
--instance-ids $INSTANCE_ID
```

---

# 22 Connect to Server

```bash
ssh -i notesapp-key.pem ec2-user@$PUBLIC_IP
```

---

# Final Infrastructure

Resources created:

* notesapp-vpc
* notesapp-subnet
* notesapp-igw
* notesapp-route-table
* notesapp-security-group
* notesapp-ec2-instance

---

# Clean Up (Avoid AWS Charges)

Terminate instance

```bash
aws ec2 terminate-instances --instance-ids $INSTANCE_ID
```

Delete remaining resources afterward.
