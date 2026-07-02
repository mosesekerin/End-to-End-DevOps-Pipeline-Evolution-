# NotesApp — End-to-End DevOps Pipeline Evolution

> A Node.js notes application evolved across five infrastructure stages — from a single bash script to a fully automated, containerised CI/CD pipeline on AWS.

---

## Table of Contents

- [Project Overview](#project-overview)
- [The Evolution Story](#the-evolution-story)
- [Final Architecture](#final-architecture)
- [Technology Stack](#technology-stack)
- [Project Structure](#project-structure)
- [Stage Breakdown](#stage-breakdown)
  - [Stage 1 — Bash Provisioning](#stage-1--bash-provisioning)
  - [Stage 2 — Terraform IaC](#stage-2--terraform-iac)
  - [Stage 3 — Ansible Configuration Management](#stage-3--ansible-configuration-management)
  - [Stage 4 — Docker Containerisation](#stage-4--docker-containerisation)
  - [Stage 5 — GitHub Actions CI/CD](#stage-5--github-actions-cicd)
- [Infrastructure Components](#infrastructure-components)
- [Deployment Guide](#deployment-guide)
- [Key Engineering Decisions](#key-engineering-decisions)
- [Challenges and How They Were Solved](#challenges-and-how-they-were-solved)
- [Skills Demonstrated](#skills-demonstrated)

---

## Project Overview

NotesApp is a minimal REST + UI notes service built with Express.js and EJS. The application itself is intentionally simple — what this project is about is the **infrastructure** that runs it.

Starting from a single bash script that manually configured an EC2 instance, this project was progressively evolved through five distinct infrastructure stages. Each stage solved a real problem that the previous stage could not handle, resulting in a production-grade automated deployment pipeline.

**The app is live at:** `http://54.172.6.245:3000`

---

## The Evolution Story

```
STAGE 1          STAGE 2          STAGE 3          STAGE 4          STAGE 5
  Bash    ──►   Terraform  ──►    Ansible   ──►    Docker    ──►   CI/CD
 Script          + Bash           + Terraform      + Ansible       Pipeline
                                  (no Bash)        + Terraform    (fully
                                                                  automated)
```

Each stage was driven by a specific pain point:

| Stage | Problem It Solved |
|-------|------------------|
| Bash | Nothing was automated — everything was manual |
| Terraform | Bash couldn't manage AWS resources as code |
| Ansible | Bash wasn't idempotent — re-runs broke things |
| Docker | App was tightly coupled to the server's OS |
| GitHub Actions | Deployment still required manual intervention |

---

## Final Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        Developer Machine                        │
│                                                                 │
│   git push origin main                                          │
└─────────────────────┬───────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────────┐
│                      GitHub Actions                             │
│                                                                 │
│   1. Checkout code                                              │
│   2. Login to Docker Hub                                        │
│   3. docker build -t mosesekerin/notesapp:latest .              │
│   4. docker push mosesekerin/notesapp:latest                    │
│   5. ansible-playbook playbooks/site.yml                        │
└──────────────┬──────────────────────────┬───────────────────────┘
               │                          │
               ▼                          ▼
┌──────────────────────┐    ┌─────────────────────────────────────┐
│      Docker Hub      │    │           AWS EC2 (t2.micro)        │
│                      │    │           Amazon Linux 2023          │
│  mosesekerin/        │    │           Elastic IP: 54.172.6.245  │
│  notesapp:latest     │    │                                     │
│                      │    │   ┌─────────────────────────────┐   │
└──────────────────────┘    │   │         systemd             │   │
               │            │   │  manages docker container   │   │
               │            │   └──────────────┬──────────────┘   │
               │            │                  │                   │
               └────────────┼──► docker pull   │                   │
                            │                  ▼                   │
                            │   ┌─────────────────────────────┐   │
                            │   │    Docker Container          │   │
                            │   │    node:18-alpine            │   │
                            │   │    NotesApp :3000            │   │
                            │   └─────────────────────────────┘   │
                            │                                     │
                            └─────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                    AWS Infrastructure (Terraform)               │
│                                                                 │
│   VPC (10.0.0.0/16)                                             │
│   └── Public Subnet (10.0.1.0/24)                              │
│       ├── Internet Gateway                                      │
│       ├── Route Table                                           │
│       ├── Security Group (ports 22, 80, 3000)                  │
│       ├── EC2 Instance (Amazon Linux 2023)                      │
│       └── Elastic IP (54.172.6.245)                            │
└─────────────────────────────────────────────────────────────────┘
```

---

## Technology Stack

| Layer | Technology | Purpose |
|-------|-----------|---------|
| Cloud | AWS EC2, VPC, Elastic IP | Infrastructure hosting |
| IaC | Terraform | AWS resource provisioning |
| Configuration | Ansible | Server configuration management |
| Containerisation | Docker, Docker Hub | App packaging and registry |
| Runtime | Node.js 18 (Alpine) | Application runtime |
| App Framework | Express.js, EJS | REST API and UI |
| Process Management | systemd | Container lifecycle management |
| CI/CD | GitHub Actions | Automated build and deployment |
| OS | Amazon Linux 2023 | Server operating system |
| Scripting | Bash | Bridge scripts and utilities |

---

## Project Structure

```
systems-evolution-lab/
├── .github/
│   └── workflows/
│       └── deploy.yml              # GitHub Actions CI/CD pipeline
│
├── Architecture/                   # Architecture diagrams and docs
│
├── Terraform/
│   ├── main.tf                     # VPC, subnet, IGW, SG, EC2, Elastic IP
│   ├── variables.tf                # Input variables
│   ├── outputs.tf                  # Exposes IP and key path
│   └── terraform.tfvars            # Variable values (gitignored)
│
├── ansible/
│   ├── ansible.cfg                 # SSH settings, inventory path
│   ├── inventory/
│   │   └── hosts.ini               # Auto-generated (gitignored)
│   └── playbooks/
│       ├── site.yml                # Entry point
│       └── configure-server.yml   # All server configuration tasks
│
├── scripts/
│   ├── configure-server.sh         # Original bash script (Stage 1)
│   ├── gen-inventory.sh            # Terraform → Ansible bridge
│   ├── setup_notesapp.sh           # App setup (called by Ansible)
│   ├── deploy.sh                   # Deployment helper
│   ├── install_service.sh          # systemd service installer
│   └── cleanup.sh                  # Cleanup utilities
│
├── systemd/
│   └── notesapp.service            # systemd unit for Docker container
│
├── views/
│   └── index.ejs                   # App UI template
│
├── docs/                           # Additional documentation
├── server.js                       # Express.js application
├── package.json                    # Node.js dependencies
├── Dockerfile                      # Container build instructions
├── .dockerignore                   # Files excluded from Docker build
└── Makefile                        # deploy, configure, destroy, check
```

---

## Stage Breakdown

### Stage 1 — Bash Provisioning

**The problem:** No automation existed. Every server required manual SSH access and running commands by hand.

**What was built:** A single bash script (`configure-server.sh`) downloaded and executed via EC2 user data on first boot.

```bash
# configure-server.sh — the entire infrastructure in one script
dnf update -y
dnf install -y git nodejs
useradd --system --create-home --shell /sbin/nologin notesapp
git clone https://github.com/mosesekerin/systems-evolution-lab.git /opt/notesapp
./scripts/setup_notesapp.sh
```

**Why it wasn't enough:**
- Ran once on boot — could not be re-run safely
- AWS resources (VPC, security groups) still created manually
- No version control over infrastructure
- Re-provisioning a server meant starting from scratch manually

---

### Stage 2 — Terraform IaC

**The problem:** AWS resources were created manually in the console. There was no record of what existed or how it was configured.

**What was built:** A complete Terraform configuration provisioning all AWS resources as code.

```
AWS Resources managed by Terraform:
├── aws_vpc.notesapp              (10.0.0.0/16)
├── aws_subnet.notesapp           (10.0.1.0/24)
├── aws_internet_gateway.notesapp
├── aws_route_table.notesapp
├── aws_security_group.notesapp   (ports 22, 80, 3000)
├── aws_key_pair.notesapp         (auto-generated RSA 4096)
├── aws_instance.notesapp         (Amazon Linux 2023, t2.micro)
└── aws_eip.notesapp              (stable Elastic IP)
```

**Key decision — AMI lookup over hardcoded ID:**
```hcl
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-*-kernel-6.1-x86_64"]
  }
}
```
Using a wildcard filter with `most_recent = true` means the pipeline never breaks when AWS retires old AMI versions.

**Key decision — Elastic IP:**
A static IP address is assigned to the EC2 instance so that the server IP never changes across infrastructure rebuilds, enabling stable DNS and stable GitHub Actions secrets.

---

### Stage 3 — Ansible Configuration Management

**The problem:** The bash user data script was not idempotent. Re-running it caused errors. There was no way to safely re-configure a running server.

**What was built:** A complete Ansible playbook replacing the bash script, with a bridge script connecting Terraform outputs to Ansible inventory.

```
Terraform apply
      │
      ▼ (outputs EC2 IP)
gen-inventory.sh
      │
      ▼ (writes hosts.ini)
ansible-playbook site.yml
      │
      ├── Update system packages   (dnf)
      ├── Install git + nodejs     (dnf)
      ├── Create notesapp user     (user module)
      ├── Create /opt/notesapp     (file module)
      ├── Clone repository         (git module)
      ├── Set file ownership       (file module)
      ├── Make scripts executable  (find + file modules)
      └── Run setup script         (shell module, as root)
```

**Key decision — Idempotency over imperative scripting:**

| Bash | Ansible |
|------|---------|
| `useradd notesapp \|\| true` | `user: state: present` |
| Fails on re-run | Safe to re-run always |
| No drift detection | Enforces desired state |
| Sequential, fragile | Declarative, reliable |

**Bridge script pattern:**
```bash
# gen-inventory.sh — reads Terraform state, writes Ansible inventory
IP=$(cd Terraform && terraform output -raw instance_public_ip)
KEY=$(cd Terraform && terraform output -raw private_key_path)
echo "[notesapp]" > ansible/inventory/hosts.ini
echo "${IP} ansible_user=ec2-user ansible_ssh_private_key_file=..." >> hosts.ini
```

---

### Stage 4 — Docker Containerisation

**The problem:** The app was tightly coupled to the server's OS. Node.js had to be installed on every server. Dependency conflicts were possible. Moving the app to a different server required reconfiguring everything.

**What was built:** A Docker image packaging the app with its runtime, pushed to Docker Hub, and managed by systemd on the server.

```dockerfile
FROM node:18-alpine

WORKDIR /app

# Copy package.json first — enables Docker layer caching
# npm install layer is reused unless dependencies change
COPY package.json .
RUN npm install --omit=dev

# Copy app code after dependencies
COPY server.js .
COPY views/ ./views/

EXPOSE 3000
CMD ["node", "server.js"]
```

**Layer caching optimisation:**
By copying `package.json` and running `npm install` before copying application code, Docker caches the dependency layer. A code change in `server.js` only invalidates the last two layers — not the `npm install` layer. This significantly speeds up rebuilds.

**systemd manages the container:**
```ini
[Unit]
Description=Notes App (Docker)
After=network.target docker.service
Requires=docker.service

[Service]
ExecStart=/usr/bin/docker run --rm -p 3000:3000 --name notesapp mosesekerin/notesapp:latest
Restart=always
RestartSec=5
```

**What Ansible now does (reduced scope):**
```
Before Docker          After Docker
─────────────────      ────────────────────
Install Node.js    →   Install Docker
Create app user    →   Start Docker service
Clone repo         →   Create log file
Run setup script   →   Create notes.json
Manage app         →   Copy systemd unit
                   →   Pull Docker image
                   →   Start notesapp service
```

---

### Stage 5 — GitHub Actions CI/CD

**The problem:** Deployment still required a developer to manually run `docker build`, `docker push`, and `ansible-playbook`. Every code change was a multi-step manual process.

**What was built:** A GitHub Actions workflow that automates the entire pipeline on every push to `main`.

```yaml
on:
  push:
    branches: [main]

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    steps:
      - Checkout code
      - Login to Docker Hub        # uses DOCKERHUB_USERNAME + DOCKERHUB_TOKEN secrets
      - Build Docker image         # docker build -t mosesekerin/notesapp:latest .
      - Push to Docker Hub         # docker push mosesekerin/notesapp:latest
      - Install Ansible
      - Write SSH key to file      # EC2_SSH_KEY secret → notesapp-key.pem
      - Write Ansible inventory    # EC2_HOST secret → hosts.ini
      - Run Ansible playbook       # pulls new image, restarts container
```

**Secrets used (stored in GitHub, never in code):**

| Secret | Value |
|--------|-------|
| `DOCKERHUB_USERNAME` | Docker Hub username |
| `DOCKERHUB_TOKEN` | Docker Hub access token (Read/Write) |
| `EC2_SSH_KEY` | Contents of notesapp-key.pem |
| `EC2_HOST` | Elastic IP (54.172.6.245) |

**End-to-end deployment time: ~1 minute 13 seconds**

---

## Infrastructure Components

### Terraform State
Terraform tracks all AWS resources in a state file (`terraform.tfstate`). This file is gitignored — it contains sensitive resource IDs and must never be committed.

### Ansible Inventory
`ansible/inventory/hosts.ini` is auto-generated by `scripts/gen-inventory.sh` after every `terraform apply`. It is gitignored because it contains live server IPs specific to the current deployment.

### Docker Image Versioning
The CI/CD pipeline tags images as `:latest`. The server always pulls `:latest`, ensuring the most recent build is always deployed.

### systemd + Docker Integration
systemd manages the Docker container as a service. On server reboot, systemd automatically starts Docker and then starts the notesapp container — no manual intervention required.

---

## Deployment Guide

### Prerequisites
- Terraform >= 1.3.0
- Ansible
- AWS CLI configured with credentials
- Docker
- Make

### Full deployment from scratch

```bash
# Clone the repository
git clone https://github.com/mosesekerin/systems-evolution-lab.git
cd systems-evolution-lab

# Provision AWS infrastructure
cd Terraform
terraform init
terraform apply

# Generate Ansible inventory from Terraform outputs
cd ..
bash scripts/gen-inventory.sh

# Configure the server
cd ansible
ansible-playbook playbooks/site.yml
```

### Or with Make (from project root)

```bash
make deploy      # full: terraform apply + gen-inventory + ansible-playbook
make configure   # ansible only (infrastructure already exists)
make check       # dry run — shows what would change without changing it
make destroy     # tear down all AWS infrastructure
```

### After any code change
```bash
git add .
git commit -m "your message"
git push origin main
# GitHub Actions handles everything from here
```

---

## Key Engineering Decisions

**1. Ansible over continued bash scripting**
Bash scripts are imperative — they tell the server what to do step by step. Ansible is declarative — it describes what the server should look like. The result is idempotent deployments that are safe to re-run at any time without side effects.

**2. Elastic IP over dynamic IP**
Every `terraform apply` on a fresh instance produces a new dynamic IP. Ansible inventory, GitHub Actions secrets, and any DNS records would all break. An Elastic IP is a fixed address that survives infrastructure rebuilds.

**3. Docker layer caching**
`package.json` is copied and `npm install` runs before application code is copied. This separates the dependency layer from the code layer in the Docker image. Dependency installation is only re-run when `package.json` changes — not on every code change.

**4. systemd managing Docker**
Rather than running the container with `docker run -d` and hoping it stays up, systemd is configured to own the container's lifecycle. This means automatic restart on failure and automatic start on server reboot.

**5. gen-inventory.sh as the Terraform-Ansible bridge**
Neither Terraform nor Ansible knows about the other. The bridge script reads Terraform's state file outputs and writes an Ansible inventory file. This keeps both tools cleanly decoupled while enabling them to work in sequence.

**6. Wildcard AMI filter**
Hardcoding a specific AMI ID breaks when AWS retires old AMI versions. A wildcard filter with `most_recent = true` always resolves to the latest available Amazon Linux 2023 image.

---

## Challenges and How They Were Solved

**`notesapp` user lacking sudo privileges**
The setup script internally called `sudo`, but the `notesapp` system user had no sudo rights by design. Resolved by running the setup task as root via the play-level `become: true`, removing the redundant `become_user` override on that specific task.

**Script on server different from local version**
The server was pulling an older version of `setup_notesapp.sh` from GitHub that still contained `sudo` calls. Diagnosed via `git diff`, committed the clean local version, and pushed — Ansible then cloned the correct version on the next run.

**Ansible pipelining breaking privilege escalation**
Adding `pipelining = True` to `ansible.cfg` caused a timeout at the Gathering Facts stage. Pipelining conflicts with `become` in certain configurations. Resolved by removing pipelining.

**Docker Hub push failing with insufficient scopes**
The Docker Hub access token was created with read-only permissions. Resolved by generating a new token with Read & Write access and updating the GitHub secret.

**SSH key path mismatch in GitHub Actions**
The PEM key was written to the workspace root, but Ansible ran from the `ansible/` subdirectory and looked for the key relative to that path. Resolved by using `${{ github.workspace }}` to write and reference the key as an absolute path.

**AMI lookup returning no results**
The Terraform AMI filter used a hardcoded AMI name that AWS had retired during a 3-month gap in the project. Resolved by updating the filter to use a wildcard pattern.

---

## Skills Demonstrated

| Skill | Evidence |
|-------|---------|
| Infrastructure as Code | Complete Terraform configuration for VPC, networking, compute, and Elastic IP |
| Configuration Management | Idempotent Ansible playbook replacing bash-based server setup |
| Containerisation | Multi-layer Dockerfile with caching optimisation, Docker Hub registry |
| CI/CD Pipeline Design | GitHub Actions workflow triggering on push, building and deploying automatically |
| Secret Management | GitHub Secrets for credentials, never hardcoded in any file |
| Process Management | systemd unit managing Docker container lifecycle |
| Debugging | Systematic diagnosis across multiple tools — Terraform, Ansible, Docker, GitHub Actions |
| Git Workflow | Feature commits, tagged milestones (v1.0, v1.1, v2.0), meaningful commit messages |
| AWS | EC2, VPC, Subnets, IGW, Security Groups, Elastic IP, AMI lookup |
| Linux | Amazon Linux 2023, systemd, file permissions, user management |

---

## Milestones

| Tag | Description |
|-----|-------------|
| `v1.0-ansible-complete` | Terraform + Ansible provisioning working end-to-end |
| `v1.1-containerised` | App containerised with Docker, image on Docker Hub |
| `v2.0-cicd-complete` | Full CI/CD pipeline with GitHub Actions |

---

*Built by [Timileyin](https://github.com/mosesekerin) — DevOps / SRE / Cloud Engineer*