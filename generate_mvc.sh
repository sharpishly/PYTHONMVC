#!/bin/bash

# This script generates the Python MVC project structure and files with improvements.

echo "Creating project directories..."

mkdir -p core models controllers views/home views/home/partials

echo "Directories created."

echo "Creating .gitignore..."
cat <<EOF > .gitignore
__pycache__/
*.pyc
venv/
.env
EOF
echo ".gitignore created."

echo "Creating requirements.txt..."
touch requirements.txt
echo "requirements.txt created."

echo "Creating core/app.py..."
cat <<EOF > core/app.py
# core/app.py

import os
import re
import logging
from controllers.home import HomeController

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class App:
    def __init__(self, base_dir):
        self.base_dir = base_dir
        self.routes = {
            '/': HomeController().index,
        }

    def _replace_placeholders(self, content, context):
        pattern = re.compile(r'{{\s*(\w+)\s*}}')
        return pattern.sub(lambda match: str(context.get(match.group(1), match.group(0))), content)

    def _include_partials(self, content):
        while '{{ partials/' in content:
            start = content.find('{{ partials/')
            end = content.find(' }}', start)
            if start != -1 and end != -1:
                partial_name = content[start + len('{{ partials/'):end].strip()
                partial_path = os.path.join(self.base_dir, 'views', *partial_name.split('/')) + '.html'
                try:
                    with open(partial_path, 'r') as p_f:
                        partial_content = p_f.read()
                    content = content[:start] + partial_content + content[end + len(' }}'):]
                except FileNotFoundError:
                    logger.warning(f"Partial '\{partial_name}.html' not found.")
                    content = content[:start] + f"<!-- Partial '\{partial_name}.html' not found -->" + content[end + len(' }}'):]
            else:
                break
        return content

    def _render_template(self, view_path, context={}):
        full_path = os.path.join(self.base_dir, 'views', view_path)
        try:
            with open(full_path, 'r') as f:
                content = f.read()

            content = self._include_partials(content)
            content = self._replace_placeholders(content, context)

            return content
        except FileNotFoundError:
            return f"Error: View '\{view_path}' not found."
        except Exception as e:
            logger.error(f"Error rendering view '\{view_path}': \{e}")
            return f"Error rendering view: \{e}"

    def handle_request(self, path):
        handler = self.routes.get(path)
        if handler:
            try:
                view_name, context = handler(self._render_template)
                return self._render_template(view_name, context)
            except Exception as e:
                logger.error(f"Error handling request for '\{path}': \{e}")
                return f"500 Internal Server Error: \{e}"
        return "404 Not Found"

if __name__ == "__main__":
    current_dir = os.path.dirname(os.path.abspath(__file__))
    project_root = os.path.dirname(current_dir)

    app = App(base_dir=project_root)

    print("--- Simulating a request to / ---")
    response = app.handle_request('/')
    print(response)

    print("\n--- Simulating a request to /nonexistent ---")
    response_404 = app.handle_request('/nonexistent')
    print(response_404)
EOF
echo "core/app.py created."

echo "Creating core/db.py..."
cat <<EOF > core/db.py
# core/db.py

class Database:
    def __init__(self):
        pass

    def get_data(self, collection_name):
        if collection_name == "home_page_data":
            return {
                "title": "Welcome to My MVC App!",
                "message": "This is a simple demonstration of the MVC pattern in Python.",
                "items": ["Item 1", "Item 2", "Item 3"]
            }
        return {}

db = Database()
EOF
echo "core/db.py created."

echo "Creating models/home.py..."
cat <<EOF > models/home.py
# models/home.py

from core.db import db

class HomeModel:
    def get_home_page_data(self):
        return db.get_data("home_page_data")
EOF
echo "models/home.py created."

echo "Creating controllers/home.py..."
cat <<EOF > controllers/home.py
# controllers/home.py

from models.home import HomeModel

class HomeController:
    def __init__(self):
        self.model = HomeModel()

    def index(self, render_template_func):
        home_data = self.model.get_home_page_data()
        items = home_data.get("items", [])
        items_html = ''.join(f"<li>\{item}</li>" for item in items)

        context = {
            "page_title": home_data.get("title", "Default Title"),
            "welcome_message": home_data.get("message", "No message."),
            "items_html": items_html
        }

        return "home/index.html", context
EOF
echo "controllers/home.py created."

echo "Creating views/home/index.html..."
cat <<EOF > views/home/index.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{{ page_title }}</title>
    <style>
        body {
            font-family: 'Inter', sans-serif;
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
            box-shadow: 0 4px 8px rgba(0, 0, 0, 0.1);
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
            box-shadow: 0 2px 4px rgba(0, 0, 0, 0.05);
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
    {{ partials/home/partials/header }}

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
</html>
EOF
echo "views/home/index.html created."

echo "Creating views/home/partials/header.html..."
cat <<EOF > views/home/partials/header.html
<!-- views/home/partials/header.html -->
<header style="background-color: #34495e; color: white; padding: 20px; text-align: center; border-radius: 12px 12px 0 0;">
    <nav>
        <a href="/" style="color: white; text-decoration: none; font-weight: bold; font-size: 1.2em; padding: 10px 15px; border-radius: 8px; transition: background-color 0.3s ease;">Home</a>
    </nav>
</header>
EOF
echo "views/home/partials/header.html created."

echo "All files and directories have been generated successfully."
echo "You can now run the application by navigating to the project root and executing: python core/app.py"
