#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

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

# Ensure we are in the correct directory before creating the venv
cd "$YOUR_PROJECT_DIR"

# Virtual environment name
VENV_DIR="venv"

# Create and activate a virtual environment if it doesn't exist
if [ ! -d "$VENV_DIR" ]; then
    echo "Creating new virtual environment: $VENV_DIR"
    python3 -m venv "$VENV_DIR" || { echo "Error: Failed to create virtual environment. Check permissions or 'python3-venv' installation."; exit 1; }
fi

# Check if the activate script exists before sourcing it
if [ ! -f "$VENV_DIR/bin/activate" ]; then
    echo "Error: Virtual environment was not created successfully. '$VENV_DIR/bin/activate' not found."
    exit 1
fi

# Activate the virtual environment
source "$VENV_DIR/bin/activate"

# Install Gunicorn within the virtual environment
echo "Installing Gunicorn..."
pip install gunicorn

# Deactivate the virtual environment
deactivate

# --- 4. Create a WSGI Entry Point ---
echo "4. Creating the Gunicorn WSGI entry point file (wsgi.py)..."
# Check if wsgi.py already exists to avoid overwriting user's file.
if [ ! -f "$YOUR_PROJECT_DIR/wsgi.py" ]; then
  cat << EOF > "$YOUR_PROJECT_DIR/wsgi.py"
import os
import sys

# Add the project directory to the Python path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from app import App

# The WSGI application must be named 'application'
def application(environ, start_response):
    request_uri = environ.get('PATH_INFO', '/')
    request_method = environ.get('REQUEST_METHOD', 'GET')

    base_dir = os.path.dirname(os.path.abspath(__file__))
    app = App(base_dir)

    response_content, status_code = app.handle_request(request_uri, method=request_method)

    # Gunicorn expects a status string (e.g., "200 OK")
    status = f"{status_code} {app.RESPONSE_CODES.get(status_code, 'Unknown')}"

    # Headers must be a list of tuples
    response_headers = [('Content-type', 'text/html')]

    start_response(status, response_headers)

    # Gunicorn expects an iterable, so we return a list containing the response content
    return [response_content.encode('utf-8')]
EOF
else
    echo "wsgi.py already exists. Skipping creation."
fi


# --- 5. Gunicorn Systemd Service Configuration ---
echo "5. Creating Gunicorn systemd service file..."
SERVICE_NAME="my_mvc_app"
SOCKET_NAME="my_mvc_app.sock"

# Change ownership of the project directory to the www-data user/group
echo "Setting project directory ownership for Gunicorn..."
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
}
EOF

# --- 7. Enabling and Starting Services ---
echo "7. Enabling and starting services..."
# Create a symbolic link to enable the Nginx configuration.
sudo ln -sf /etc/nginx/sites-available/${NGINX_CONF_NAME} /etc/nginx/sites-enabled/
# Remove the default Nginx configuration to prevent conflicts.
sudo rm -f /etc/nginx/sites-enabled/default

# Start and enable the Gunicorn service.
sudo systemctl daemon-reload
sudo systemctl start ${SERVICE_NAME}
sudo systemctl enable ${SERVICE_NAME}

# Check Gunicorn service status.
sudo systemctl status ${SERVICE_NAME} --no-pager || echo "Gunicorn service failed to start. Check logs with 'journalctl -u ${SERVICE_NAME}.service'."

# Test Nginx configuration and restart the service.
sudo nginx -t
sudo systemctl restart nginx
sudo systemctl enable nginx

# --- 8. Configure Firewall (UFW) ---
echo "8. Configuring firewall to allow HTTP traffic..."
sudo ufw allow "Nginx Full"
sudo ufw enable

echo "--- Installation complete! ---"
echo "Your application should now be accessible at http://${YOUR_DOMAIN_OR_IP}"
echo ""
echo "To verify the Gunicorn service is running, use:"
echo "    sudo systemctl status ${SERVICE_NAME}"
echo ""
echo "To check for Gunicorn errors, use:"
echo "    sudo journalctl -u ${SERVICE_NAME}.service"
echo ""
echo "If you made changes to your code, remember to reload the Gunicorn service:"
echo "    sudo systemctl reload ${SERVICE_NAME}"
