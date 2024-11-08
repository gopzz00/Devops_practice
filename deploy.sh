#!/bin/bash

# Sample DevOps Shell Script for Automated Deployment and Monitoring

# Variables
APP_NAME="my_web_app"
APP_DIR="/var/www/$APP_NAME"
REPO_URL="https://github.com/username/my_web_app.git"
LOG_FILE="/var/log/$APP_NAME-deploy.log"
SERVICE_NAME="my_web_app_service"

# Functions

# Log output to console and log file
log() {
    echo "$(date +"%Y-%m-%d %T") : $1" | tee -a $LOG_FILE
}

# Step 1: Update System Packages
log "Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Step 2: Install Necessary Dependencies (Nginx, Git, Node.js as an example)
log "Installing necessary dependencies..."
sudo apt install -y nginx git nodejs npm

# Step 3: Clone Repository (or pull latest changes if the repo exists)
if [ -d "$APP_DIR" ]; then
    log "Updating existing application repository..."
    cd "$APP_DIR" && git pull origin main
else
    log "Cloning application repository..."
    git clone "$REPO_URL" "$APP_DIR"
fi

# Step 4: Install Application Dependencies
log "Installing application dependencies..."
cd "$APP_DIR" || exit
npm install

# Step 5: Build the Application
log "Building the application..."
npm run build

# Step 6: Configure Nginx (Optional - to serve the app)
NGINX_CONF="/etc/nginx/sites-available/$APP_NAME"
if [ ! -f "$NGINX_CONF" ]; then
    log "Configuring Nginx for the application..."
    sudo bash -c "cat > $NGINX_CONF <<EOF
server {
    listen 80;
    server_name example.com;

    location / {
        root $APP_DIR/build;
        try_files \$uri /index.html;
    }
}
EOF"
    sudo ln -s "$NGINX_CONF" /etc/nginx/sites-enabled/
    sudo nginx -s reload
fi

# Step 7: Start the Application Service
log "Starting application service..."
sudo systemctl restart "$SERVICE_NAME" || sudo systemctl start "$SERVICE_NAME"

# Step 8: Health Check
log "Performing health check..."
RESPONSE=$(curl -o /dev/null -s -w "%{http_code}" http://localhost)
if [ "$RESPONSE" -eq 200 ]; then
    log "Health check passed: Application is running successfully."
else
    log "Health check failed: Application returned status code $RESPONSE."
fi

# Step 9: Setup Log Rotation (Optional - if log rotation isn't already configured)
LOGROTATE_CONF="/etc/logrotate.d/$APP_NAME"
if [ ! -f "$LOGROTATE_CONF" ]; then
    log "Setting up log rotation for application logs..."
    sudo bash -c "cat > $LOGROTATE_CONF <<EOF
$LOG_FILE {
    daily
    missingok
    rotate 14
    compress
    delaycompress
    notifempty
    create 640 root adm
    sharedscripts
}
EOF"
fi

# Step 10: Clean Up Old Builds (Optional)
log "Cleaning up old builds..."
find "$APP_DIR/build" -type f -mtime +30 -exec rm -f {} \;

# Completion Message
log "Deployment script completed."
