#!/bin/bash

# Usage: ./bake.sh [module_name]
MODULE_NAME=${1:-home}
CAPITALIZED_MODULE_NAME="$(tr '[:lower:]' '[:upper:]' <<< ${MODULE_NAME:0:1})${MODULE_NAME:1}"

# Create directories
mkdir -p controllers
mkdir -p models
mkdir -p views/"$MODULE_NAME"/partials

# Create controller
cat > controllers/"$MODULE_NAME".py <<EOF
from models.$MODULE_NAME import ${CAPITALIZED_MODULE_NAME}Model

class ${CAPITALIZED_MODULE_NAME}Controller:
    def __init__(self):
        self.model = ${CAPITALIZED_MODULE_NAME}Model()

    def index(self, render_template_func):
        data = self.model.get_home_page_data()
        items = data.get("items", [])
        items_html = ''.join(f"<li>{item}</li>" for item in items)
        context = {
            "page_title": data.get("title", "Default Title"),
            "welcome_message": data.get("message", "No message."),
            "items_html": items_html
        }
        return "$MODULE_NAME/index.html", context

    def show(self, render_template_func):
        data = self.model.get_home_page_data()
        items = data.get("items", [])
        items_html = ''.join(f"<li>{item}</li>" for item in items)
        context = {
            "page_title": data.get("title", "Default Title"),
            "welcome_message": data.get("message", "No message."),
            "items_html": items_html
        }
        return "$MODULE_NAME/show.html", context

    def greet(self, render_template_func, name="Guest"):
        context = {
            "page_title": f"Greetings, {name}!",
            "message": f"Hello there, {name}! Welcome to our custom MVC app."
        }
        return "$MODULE_NAME/greet.html", context
EOF

# Create model
cat > models/"$MODULE_NAME".py <<EOF
from core.db import db

class ${CAPITALIZED_MODULE_NAME}Model:
    def get_home_page_data(self):
        return db.get_data("${MODULE_NAME}_page_data")
EOF

# Create view template
TEMPLATE='<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{{ page_title }}</title>
    <style>
        body {
            font-family: "Inter", sans-serif;
            margin: 0;
            padding: 0;
            background-color: #f4f7f6;
            color: #333;
            display: flex;
            flex-direction: column;
            min-height: 100vh;
        }
        .container {
            max-width: 800px;
            margin: 20px auto;
            padding: 20px;
            background-color: #ffffff;
            border-radius: 12px;
            box-shadow: 0 4px 8px rgba(0,0,0,0.1);
            flex-grow: 1;
        }
        h1 {
            color: #2c3e50;
            text-align: center;
            margin-bottom: 20px;
            border-bottom: 2px solid #e0e0e0;
            padding-bottom: 10px;
        }
        p {
            line-height: 1.6;
            margin-bottom: 15px;
            text-align: center;
        }
        ul {
            list-style-type: none;
            padding: 0;
            margin-top: 20px;
            display: flex;
            flex-wrap: wrap;
            justify-content: center;
            gap: 10px;
        }
        li {
            background-color: #e8f0fe;
            padding: 10px 20px;
            border-radius: 8px;
            margin-bottom: 5px;
            font-weight: bold;
            color: #2a64b9;
            box-shadow: 0 2px 4px rgba(0,0,0,0.05);
        }
        footer {
            text-align: center;
            padding: 20px;
            margin-top: 30px;
            background-color: #e0e0e0;
            color: #555;
            border-radius: 0 0 12px 12px;
        }
    </style>
</head>
<body>
    {{ partials/'$MODULE_NAME'/partials/header }}

    <div class="container">
        <h1>{{ page_title }}</h1>
        <p>{{ welcome_message }}</p>

        <h2>Some Items:</h2>
        <ul>
            {{ items_html }}
        </ul>
    </div>

    <footer>
        <p>&copy; 2024 My MVC App. All rights reserved.</p>
    </footer>
</body>
</html>'

echo "$TEMPLATE" > views/"$MODULE_NAME"/index.html
echo "$TEMPLATE" > views/"$MODULE_NAME"/show.html
echo "$TEMPLATE" > views/"$MODULE_NAME"/greet.html

# Create header partial
cat > views/"$MODULE_NAME"/partials/header.html <<EOF
<header style="background-color: #34495e; color: white; padding: 20px; text-align: center; border-radius: 12px 12px 0 0;">
    <nav>
        <a href="/" style="color: white; text-decoration: none; font-weight: bold; font-size: 1.2em; padding: 10px 15px; border-radius: 8px; transition: background-color 0.3s ease;">Home</a>
    </nav>
</header>
EOF

echo "✅ Module '$MODULE_NAME' baked successfully."
