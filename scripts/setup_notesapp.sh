#!/bin/bash
set -e

echo "Installing application dependencies..."
cd /opt/notesapp
npm install --omit=dev

echo "Preparing persistent storage..."
touch /opt/notesapp/notes.json
chown notesapp:notesapp /opt/notesapp/notes.json

echo "Preparing log file..."
touch /var/log/notesapp.log
chown notesapp:notesapp /var/log/notesapp.log

echo "Preparing systemd for service management"
./scripts/install_service.sh