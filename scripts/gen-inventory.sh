#!/bin/bash
# scripts/gen-inventory.sh
# Reads Terraform outputs and writes the Ansible inventory.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INVENTORY_FILE="$SCRIPT_DIR/../ansible/inventory/hosts.ini"
TERRAFORM_DIR="$SCRIPT_DIR/../Terraform"

echo "Reading Terraform outputs..."
IP=$(cd "$TERRAFORM_DIR" && terraform output -raw public_ip)
KEY=$(cd "$TERRAFORM_DIR" && terraform output -raw private_key_path)

mkdir -p "$(dirname "$INVENTORY_FILE")"

cat > "$INVENTORY_FILE" <<EOF
[notesapp]
${IP} ansible_user=ec2-user ansible_ssh_private_key_file=${TERRAFORM_DIR}/${KEY} ansible_ssh_common_args='-o StrictHostKeyChecking=no'
EOF

echo "Inventory written → $INVENTORY_FILE (${IP})"
