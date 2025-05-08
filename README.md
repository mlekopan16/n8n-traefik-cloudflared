# Self-hosted N8N with Traefik and Cloudflared Tunnel

This repository contains a Docker Compose setup for running N8N workflow automation tool with Traefik as reverse proxy and Cloudflare Tunnel for secure remote access.

## 🚀 Features

- N8N workflow automation platform, with working webhooks
- Traefik as reverse proxy with security headers
- Cloudflare Zero Trust Tunnel for secure remote access
- PostgreSQL database for data persistence
- Docker-based setup for easy deployment

## 📋 Prerequisites

- I have been using this on my home SFF server with Proxmox installed:
  - Using [GMKTEC NucBox G3](https://www.gmktec.com/products/nucbox-g3-most-cost-effective-mini-pc-with-intel-n100-processor)
  - LXC container with Docker preinstalled on Debian - using [Proxmox Docker installation script](https://community-scripts.github.io/ProxmoxVE/scripts?id=docker)
  - Recommended: At least 6GB disk space for the container

### Requirements
- Cloudflare account with Zero Trust enabled
- Domain name bought through Cloudflare, or pointing to Cloudflare
- Basic understanding of Docker and networking

## 🛠️ Installation

1. Clone this repository:
```bash
git clone https://github.com/yourusername/n8n-traefik-cloudflared.git
cd n8n-traefik-cloudflared
```

2. Update the `.env` file with your settings:
   - Set your domain name
   - Configure N8N credentials
   - Set PostgreSQL passwords
   - Add your Cloudflare Tunnel token

3. Create required directories:
```bash
mkdir -p n8n/data postgres cloudflared
```

4. Once your domain is either bought through Cloudflare or pointing to Cloudflare, create a Zero Trust tunnel:
    - Go to Networks > Tunnels > Create tunnel > Cloudflared
    - Give your tunnel a name and save it
    - Copy your Cloudflared tunnel token (keep it secure) and paste it into your .env file
    - In your tunnel settings, add Public Hostname with these details:
        * Subdomain: your chosen subdomain that will be used with <your-domain>
        * Domain: select your domain from the list
        * Type: HTTP
        * URL: localhost:5678
        
    Save everything.

5. One small adjustment that has to be done inside your LXC container:
    - Run this in terminal:
        ```bash
        sudo chown -R 1000:1000 <your-working-folder>/n8n
        sudo chmod -R 755 <your-working-folder>/n8n
        ```

6. Start the stack:
    ```bash
    docker-compose up -d
    ```

7. If something is not working, check the logs:
    ```bash
    docker logs cloudflared --tail 100
    docker logs n8n --tail 100
    docker logs traefik --tail 100
    ```

8. When making changes, ideally rebuilt Docker containers using command:
    ```bash
    docker compose down && docker compose up --force-recreate --build --detach
    ```

## 🔄 Updating and Maintenance
It's crucial to keep your services and the underlying system up-to-date. This project includes an update script named `stack-update.sh` located in the root directory to help automate this process.

### 1. Review the Update Script

The `stack-update.sh` script is designed to:
- Pull the latest Docker images for all services defined in your `docker-compose.yml`.
- Rebuild the Docker Compose stack using `docker compose down` and `docker compose up --force-recreate --build --detach`
- Update the underlying Debian system using `sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y` (change this if needed)
- Clean up unused Docker resources (containers, networks, images) using `docker system prune -a -f`.
- Log its actions to a `update.log` file within the project directory.

**Important:** Before using it, please open `stack-update.sh` from the root of this project and review its commands to ensure you understand what it does.
The script attempts to change to the directory where it's located (`COMPOSE_DIR="."`), which should be the root of your project for `docker-compose.yml` to be found.

### 2. Make the script executable

Navigate to the project's root directory (where `stack-update.sh` is located) and run:
```bash
chmod +x stack-update.sh
```

### 3. Test the script manually
Before automating, it's highly recommended to run the script manually once to ensure it works correctly in your environment:
```bash
sudo ./stack-update.sh
```
(You will likely need sudo because the script performs system updates (apt) and manages Docker, which often requires elevated privileges depending on your setup.)
Check the console output and the generated stack-update.log file in the project directory for any errors or unexpected behavior.

### 4. Automate with Cron (for example to run every week)
To schedule the script to run automatically (e.g., every Sunday at midnight):
1. Open the root user's crontab for editing. Using root's crontab is often simplest for scripts that require sudo permissions:
```bash
sudo crontab -e
```
(If it's your first time, you might be prompted to choose an editor like nano.)

2. Add the following line to the end of the file. Remember to replace /path/to/your/project/directory/ with the actual absolute path to where you cloned this repository or your stack-update.sh file is.
```bash
0 0 * * 0 /path/to/your/project/directory/stack-update.sh
```
For example, if your project is in /root/n8n-stack:
```bash
0 0 * * 0 /root/n8n-stack/stack-update.sh
```
3. Save and close the crontab file.
(If using nano: Ctrl+X, then Y to confirm, then Enter to save.)

This cron job will now execute your stack-update.sh script every Sunday at 00:00 (midnight), helping to keep your deployment updated.

## 🔧 Configuration

### Environment Variables

| Variable | Description |
|----------|-------------|
| DOMAIN_NAME | Your domain name |
| N8N_HOST | N8N subdomain |
| N8N_BASIC_AUTH_ACTIVE | Enable/disable basic auth |
| N8N_USER | N8N admin username |
| N8N_PASSWORD | N8N admin password |
| POSTGRES_USER | Database username |
| POSTGRES_DB | Database name |
| N8N_POSTGRES_PASSWORD | Database password |
| CLOUDFLARE_TUNNEL_TOKEN | Cloudflare tunnel token |

### Security Features

- TLS 1.2+ with strong cipher suites
- Security headers enabled
- Rate limiting
- Basic authentication
- Zero Trust access through Cloudflare Tunnel

## 📂 Project Structure

```
.
├── .env                 # Environment configuration
├── docker-compose.yml   # Docker services configuration
├── traefik/
│   ├── traefik.yml     # Traefik configuration
│   └── configurations/  # Additional Traefik configs
├── n8n/
│   └── data/           # N8N data persistence
├── postgres/           # PostgreSQL data
└── cloudflared/        # Cloudflare tunnel configs
```

## 🔒 Security Recommendations

1. Keep your Cloudflare Tunnel token secure
2. Enable 2FA on your Cloudflare account
3. Regularly update Docker images
4. Monitor logs for suspicious activities
5. Adjust your Cloudflare Access Policies, to for example block access for people in China, Russia, India. This should prevent loads of bots scanning your environment.
6. Make sure your SSL/TLS encryption is at least 'Full' in your domain settings. Use TLS in at least v1.2 setting.

## 🚀 Accessing Services

- N8N: `https://your-subdomain.yourdomain.com`
- Traefik Dashboard: `http://ip-of-lxc-container:8080/dashboard/#/` - should be accessible only internally


## ⚠️ Important Notes

- Backup your data regularly
- Keep your environment variables secure
- Monitor system resources
- Check for updates regularly

## 👮‍♂️ Note about Traefik

Traefik is already preconfigured with the following security features:

### Rate Limiting
- Limits requests to 100 per second on average
- Allows bursts up to 50 requests

### Security Headers
- Enables XSS protection
- Prevents MIME-type sniffing
- Blocks iframe embedding
- Forces SSL
- Configures HSTS (strict HTTPS)
- Hides server info
- Blocks search engine indexing

### TLS Settings
- Enforces TLS 1.2 minimum
- Requires SNI (Server Name Indication)
- Uses strong cipher suites for encryption

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request
