#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Configuration ---
# You MUST change these variables to match your setup.
# The absolute path to your project directory.
YOUR_PROJECT_DIR="/var/www/py"
# Your domain name or droplet's public IP address.
YOUR_DOMAIN_OR_IP="py.sharpishly.com"
# The name of your Gunicorn service file.
SERVICE_NAME="my_mvc_app"
# The name of the Gunicorn socket file.
SOCKET_NAME="my_mvc_app.sock"
# The name of the Nginx configuration file.
NGINX_CONF_NAME="my_mvc_app_nginx"
# The name of the virtual environment directory.
VENV_DIR="venv"

echo "--- Starting installation for Python MVC application ---"

# --- 1. System Update and Dependencies Installation ---
echo "1. Updating system packages and installing required software..."
sudo apt-get update -y
sudo apt-get install -y python3 python3-pip python3-venv nginx

# --- 2. Virtual Environment and Python Packages ---
echo "2. Setting up Python virtual environment and dependencies..."
cd "$YOUR_PROJECT_DIR"

# Create and activate a virtual environment
if [ ! -d "$VENV_DIR" ]; then
    python3 -m venv "$VENV_DIR"
fi
source "$VENV_DIR/bin/activate"

# Install Gunicorn. The provided code is library-free, but Gunicorn is needed
# to run it as a web server.
pip install gunicorn

# --- 3. Create a WSGI Entry Point ---
# Your `app.py` is not a standard WSGI application. We need a small wrapper
# to make it compatible with Gunicorn. This script will create a wsgi.py file.
echo "3. Creating the Gunicorn WSGI entry point file (wsgi.py)..."
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
    # This is a very simple WSGI handler.
    # In a real app, you'd parse method and headers from 'environ'.
    request_uri = environ.get('PATH_INFO', '/')
    request_method = environ.get('REQUEST_METHOD', 'GET')
    
    # Instantiate the application and handle the request
    # NOTE: The App constructor needs a base_dir, which we'll get from the environ
    # In the provided code, `app.py` determines the base_dir from the script's location.
    # We will replicate that behavior here.
    base_dir = os.path.dirname(os.path.abspath(__file__))
    app = App(base_dir)

    # The handle_request method returns a tuple (response_content, status_code)
    response_content, status_code = app.handle_request(request_uri, method=request_method)
    
    # Gunicorn expects a status string (e.g., "200 OK")
    status = f"{status_code} {app.RESPONSE_CODES.get(status_code, 'Unknown')}"
    
    # Headers must be a list of tuples
    response_headers = [('Content-type', 'text/html')]
    
    start_response(status, response_headers)
    
    # Gunicorn expects an iterable, so we return a list containing the response content
    return [response_content.encode('utf-8')]
EOF
fi

# --- 4. Gunicorn Systemd Service Configuration ---
echo "4. Creating Gunicorn systemd service file..."
# Gunicorn will run as a service, listening on a Unix socket.
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

# --- 5. Nginx Reverse Proxy Configuration ---
echo "5. Creating Nginx configuration file..."
# Nginx will listen for web requests and forward them to Gunicorn via the socket.
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

# --- 6. Enabling and Starting Services ---
echo "6. Enabling and starting services..."
# Create a symbolic link to enable the Nginx configuration.
sudo ln -s /etc/nginx/sites-available/${NGINX_CONF_NAME} /etc/nginx/sites-enabled/
# Remove the default Nginx configuration to prevent conflicts.
sudo rm /etc/nginx/sites-enabled/default

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

# --- 7. Configure Firewall (UFW) ---
echo "7. Configuring firewall to allow HTTP traffic..."
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

echo "🚀 Installing Python MVC App..."

# Step 1: Create virtual environment
if [ ! -d "venv" ]; then
    echo "📦 Creating virtual environment..."
    python3 -m venv venv
else
    echo "✅ Virtual environment already exists."
fi

# Step 2: Activate virtual environment
echo "🔧 Activating virtual environment..."
source venv/bin/activate

# Step 3: Install Flask if needed
if ! pip show flask &> /dev/null; then
    echo "📥 Installing Flask..."
    pip install flask
    echo "flask" > requirements.txt
else
    echo "✅ Flask is already installed."
fi

# Step 4: Ensure __init__.py exists
echo "📁 Ensuring __init__.py files exist..."
touch core/__init__.py
touch models/__init__.py
touch controllers/__init__.py

# Step 5: Option to start server
echo ""
read -p "Do you want to start the Flask server now? (y/n): " start_now

if [[ "$start_now" =~ ^[Yy]$ ]]; then
    echo "🚀 Starting Flask server..."
    python runserver.py
else
    echo "✅ Setup complete. You can run the server later using: source venv/bin/activate && python runserver.py"
fi
