#!/bin/bash
set -e

echo "Starting NotesApp service..."
systemctl start notesapp

echo "Enabling service at boot..."
systemctl enable notesapp

echo "Deployment complete."
echo "Check logs with: tail -f /var/log/notesapp.log"
echo "Check status with: sudo systemctl status notesapp"