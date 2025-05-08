#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

echo "----------------------------------------------------"
echo "Starting weekly update script at $(date)"
echo "----------------------------------------------------"

# Define the directory where your docker-compose.yml is located
COMPOSE_DIR="/root/n8n-stack" # <--- IMPORTANT: Make sure this path is correct!
LOG_FILE="weekly-update.log"

# Redirect all output to a log file
exec > >(tee -a "${LOG_FILE}") 2>&1

echo "Navigating to Docker Compose directory: ${COMPOSE_DIR}"
cd "${COMPOSE_DIR}" || { echo "Failed to navigate to ${COMPOSE_DIR}. Exiting."; exit 1; }

echo "--- Pulling latest Docker images ---"
docker pull traefik:latest
docker pull postgres:latest
docker pull cloudflare/cloudflared:latest
docker pull nginx:alpine
docker pull n8nio/n8n:latest

echo "--- Rebuilding Docker Compose stack ---"
docker compose down
docker compose up --force-recreate --build --detach

echo "--- Updating Debian system ---"
# Using noninteractive frontend to avoid prompts during apt upgrade
sudo DEBIAN_FRONTEND=noninteractive apt update
sudo DEBIAN_FRONTEND=noninteractive apt upgrade -y
sudo apt autoremove -y # Optional: remove orphaned packages

echo "--- Cleaning up Docker resources ---"
# The -f flag forces the prune without prompting for confirmation
docker system prune -a -f # -a prunes all unused images, not just dangling ones

echo "----------------------------------------------------"
echo "Weekly update script finished at $(date)"
echo "----------------------------------------------------"

exit 0