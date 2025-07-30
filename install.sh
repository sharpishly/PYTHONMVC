#!/bin/bash

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
