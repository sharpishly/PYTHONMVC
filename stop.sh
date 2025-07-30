#!/bin/bash

echo -e "\n🛑 Stopping Flask server..."

# Find and kill Flask runserver process (avoid killing other python apps)
FLASK_PID=$(ps aux | grep "[r]unserver.py" | awk '{print $2}')
if [ -n "$FLASK_PID" ]; then
    kill "$FLASK_PID"
    echo "✅ Flask server (PID: $FLASK_PID) stopped."
else
    echo "ℹ️ No Flask server running."
fi

# Deactivate virtual environment if active
if [[ "$VIRTUAL_ENV" != "" ]]; then
    deactivate
    echo "🔌 Virtual environment deactivated."
else
    echo "ℹ️ No active virtual environment to deactivate."
fi

# Optional: Restart Apache or Nginx
read -p "🔁 Restart Apache or Nginx? (a = Apache, n = Nginx, enter to skip): " choice

case "$choice" in
    a|A)
        echo "🚀 Starting Apache..."
        sudo systemctl start apache2
        ;;
    n|N)
        echo "🚀 Starting Nginx..."
        sudo systemctl start nginx
        ;;
    *)
        echo "❌ Skipping web server restart."
        ;;
esac

echo -e "\n✅ Cleanup complete."
