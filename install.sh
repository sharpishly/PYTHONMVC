#!/bin/bash

# Exit on errors and treat unset variables as errors
set -euo pipefail

# --- 1. User Configuration ---
echo "--- Starting interactive installation for Python MVC application ---"

# Prompt the user for the project directory
read -p "Enter the absolute path to your Python MVC project directory (e.g., /var/www/py): " YOUR_PROJECT_DIR

# Prompt the user for their domain or IP address
read -p "Enter your droplet's domain name or IP address (e.g., example.com or 142.93.35.160): " YOUR_DOMAIN_OR_IP

# Validate that the provided directory exists
if [ ! -d "$YOUR_PROJECT_DIR" ]; then
    echo "Error: The project directory '$YOUR_PROJECT_DIR' does not exist."
    echo "Please check the path and try again."
    exit 1
fi

echo "Configuration accepted. Proceeding with installation..."

# --- 2. System Update and Dependencies Installation ---
echo "2. Updating system packages and installing required software..."
sudo apt-get update -y
sudo apt-get install -y python3 python3-pip python3-venv nginx

# --- 3. Virtual Environment and Python Packages ---
echo "3. Setting up Python virtual environment and dependencies..."

cd "$YOUR_PROJECT_DIR"

# Prevent creating a venv while inside another
if [[ "${VIRTUAL_ENV:-}" != "" ]]; then
    echo "Error: You're already inside a virtual environment. Please deactivate it and rerun the script."
    exit 1
fi

# Set ownership before virtual environment setup
sudo chown -R $USER:$USER "$YOUR_PROJECT_DIR"

VENV_DIR="venv"

# Remove broken venv if it exists
if [ -d "$VENV_DIR" ] && [ ! -f "$VENV_DIR/bin/activate" ]; then
    echo "Removing broken virtual environment..."
    rm -rf "$VENV_DIR"
fi

# Create and activate a virtual environment
if [ ! -d "$VENV_DIR" ]; then
    echo "Creating new virtual environment: $VENV_DIR"
    python3 -m venv "$VENV_DIR" || { echo "Error: Failed to create virtual environment."; exit 1; }
fi

if [ ! -f "$VENV_DIR/bin/activate" ]; then
    echo "Error: Virtual environment was not created successfully. '$VENV_DIR/bin/activate' not found."
    exit 1
fi

source "$VENV_DIR/bin/activate"

echo "Installing Gunicorn..."
pip install --upgrade pip
pip install gunicorn

deactivate

# --- 4. Create a WSGI Entry Point ---
echo "4. Creating the Gunicorn WSGI entry point file (wsgi.py)..."
if [ ! -f "$YOUR_PROJECT_DIR/wsgi.py" ]; then
  cat << EOF > "$YOUR_PROJECT_DIR/wsgi.py"
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from app import App

def application(environ, start_response):
    request_uri = environ.get('PATH_INFO', '/')
    request_method = environ.get('REQUEST_METHOD', 'GET')

    base_dir = os.path.dirname(os.path.abspath(__file__))
    app = App(base_dir)

    response_content, status_code = app.handle_request(request_uri, method=request_method)

    status = f"{status_code} {app.RESPONSE_CODES.get(status_code, 'Unknown')}"
    response_headers = [('Content-type', 'text/html')]

    start_response(status, response_headers)

    return [response_content.encode('utf-8')]
EOF
else
    echo "wsgi.py already exists. Skipping creation."
fi

# --- 5. Gunicorn Systemd Service Configuration ---
echo "5. Creating Gunicorn systemd service file..."
SERVICE_NAME="my_mvc_app"
SOCKET_NAME="my_mvc_app.sock"

sudo chown -R www-data:www-data "$YOUR_PROJECT_DIR"

cat << EOF | sudo tee /etc/systemd/system/${SERVICE_NAME}.service > /dev/null
[Unit]
Description=Gunicorn instance to serve my Python MVC app
After=network.target

[Service]
User=www-data
Group=www-data
WorkingDirectory=${YOUR_PROJECT_DIR}
ExecStart=${YOUR_PROJECT_DIR}/${VENV_DIR}/bin/gunicorn --workers 3 --bind unix:${YOUR_PROJECT_DIR}/${SOCKET_NAME} wsgi:application
UMask=007

[Install]
WantedBy=multi-user.target
EOF

# --- 6. Nginx Reverse Proxy Configuration ---
echo "6. Creating Nginx configuration file..."
NGINX_CONF_NAME="my_mvc_app_nginx"

cat << EOF | sudo tee /etc/nginx/sites-available/${NGINX_CONF_NAME} > /dev/null
server {
    listen 80;
    server_name ${YOUR_DOMAIN_OR_IP};

    location / {
        include proxy_params;
        proxy_pass http://unix:${YOUR_PROJECT_DIR}/${SOCKET_NAME};
    }

    location /static/ {
        alias ${YOUR_PROJECT_DIR}/static/;
    }
}
EOF

# --- 7. Enabling and Starting Services ---
echo "7. Enabling and starting services..."
sudo ln -sf /etc/nginx/sites-available/${NGINX_CONF_NAME} /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default

sudo systemctl daemon-reload
sudo systemctl start ${SERVICE_NAME}
sudo systemctl enable ${SERVICE_NAME}

sudo systemctl status ${SERVICE_NAME} --no-pager || echo "Gunicorn service failed to start. Check logs with 'journalctl -u ${SERVICE_NAME}.service'."

sudo nginx -t
sudo systemctl restart nginx
sudo systemctl enable nginx

# --- 8. Configure Firewall (UFW) ---
echo "8. Configuring firewall to allow HTTP traffic..."
if sudo ufw status | grep -q inactive; then
    sudo ufw allow "Nginx Full"
    sudo ufw --force enable
else
    echo "UFW already enabled. Ensuring Nginx Full profile is allowed..."
    sudo ufw allow "Nginx Full"
fi

# --- Final Message ---
echo ""
echo "--- ✅ Installation complete! ---"
echo "Your application should now be accessible at: http://${YOUR_DOMAIN_OR_IP}"
echo ""
echo "🧪 To verify Gunicorn is running:"
echo "    sudo systemctl status ${SERVICE_NAME}"
echo ""
echo "🧾 To view logs:"
echo "    sudo journalctl -u ${SERVICE_NAME}.service"
echo ""
echo "🔁 To reload Gunicorn after code changes:"
echo "    sudo systemctl reload ${SERVICE_NAME}"
echo ""
echo "🔒 For production, secure your app with HTTPS:"
echo "    https://certbot.eff.org/instructions"
echo ""
echo "📁 Ensure your static files are located in:"
echo "    ${YOUR_PROJECT_DIR}/static/"
# --- Additional commands below ---