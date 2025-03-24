#!/bin/bash
set -e

echo "Starting local web server for IoT Perimeter Manager UI..."
echo "Access the UI at: http://localhost:8000/fleet-manager.html"
echo "Press Ctrl+C to stop the server"

# Change to the ui directory
cd "$(dirname "$0")"

# Start a simple HTTP server
python3 -m http.server 8000 