#!/bin/bash
set -e

echo "Installing systemd service..."
cp /opt/notesapp/systemd/notesapp.service /etc/systemd/system/notesapp.service

echo "Reloading systemd..."
systemctl daemon-reexec
systemctl daemon-reload

echo "Starting the notesapp service"
./scripts/deploy.sh