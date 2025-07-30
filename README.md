# Python MVC Flask Application

A simple Python MVC (Model-View-Controller) web application built with Flask, served using Gunicorn, and optionally reverse-proxied via Nginx for production-like deployment. Designed to run inside a Linux VM but adaptable for other environments.

---

## Table of Contents

* [Project Overview](#project-overview)
* [Installation](#installation)
* [Project Structure & MVC Framework](#project-structure--mvc-framework)
* [Running Locally (Development)](#running-locally-development)
* [Production Deployment](#production-deployment)
* [Nginx Configuration](#nginx-configuration)
* [Troubleshooting](#troubleshooting)
* [Future Improvements](#future-improvements)
* [License](#license)

---

## Project Overview

This project demonstrates a minimal MVC web app using Flask:

* **Model**: Business logic, data handling, database interactions (not included in this minimal example).
* **View**: HTML templates or responses served to the client.
* **Controller**: Routes and logic to handle incoming requests and return responses.

---

## Installation

### Prerequisites

* Python 3.10+
* `virtualenv` for Python environment isolation
* `pip` for Python package management
* `gunicorn` for WSGI HTTP server
* `nginx` for reverse proxy (optional, recommended for production)
* `sudo` privileges for system operations

### Steps

1. **Clone the repository:**

   ```bash
   git clone https://your-repo-url.git
   cd your-repo-folder
   ```

2. **Create and activate a virtual environment:**

   ```bash
   python3 -m venv venv
   source venv/bin/activate
   ```

3. **Install dependencies:**

   ```bash
   pip install -r requirements.txt
   ```

4. **Verify Flask app works:**

   ```bash
   flask run
   ```

---

## Project Structure & MVC Framework

```
/your-project-root
├── core/                # Core app logic, MVC components (App class, models, controllers)
├── static/              # Static assets (CSS, JS, images)
├── templates/           # HTML templates (views)
├── venv/                # Virtual environment directory
├── wsgi.py              # WSGI entry point for Gunicorn
├── runserver.py         # Development server starter script
├── requirements.txt     # Python dependencies
└── README.md            # This file
```

* `core/app.py` contains your MVC application class that manages routing and responses.
* `wsgi.py` exposes the Flask app as `application` for Gunicorn.
* `runserver.py` runs the Flask development server with debug enabled.

---

## Running Locally (Development)

Activate your virtual environment and run the Flask development server:

```bash
source venv/bin/activate
python runserver.py
```

By default, it will run on:

```
http://127.0.0.1:5000
```

Accessible only from within the local machine (or VM).

---

## Production Deployment

Use **Gunicorn** as the production-grade WSGI HTTP server.

Run Gunicorn, binding to localhost on port 8000:

```bash
source venv/bin/activate
gunicorn --bind 127.0.0.1:8000 wsgi:application
```

---

## Nginx Configuration

Use Nginx as a reverse proxy to forward requests from port 80 to Gunicorn.

### Example config (`/etc/nginx/sites-available/flask_mvc.conf`):

```nginx
server {
    listen 80;
    server_name python.skyprime.com;

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
```

### Enable the site and reload Nginx:

```bash
sudo ln -s /etc/nginx/sites-available/flask_mvc.conf /etc/nginx/sites-enabled/
sudo systemctl restart nginx
```

Make sure your host machine’s `/etc/hosts` file includes:

```
192.168.0.57 python.skyprime.com
```

Update the IP to match your VM’s address.

---

## Troubleshooting

### ❌ Cannot access app from host

* ✅ Confirm Gunicorn is running and listening on `127.0.0.1:8000` inside the VM.
* ✅ Confirm Nginx is running and properly proxying requests.
* ✅ Check your VM network settings (prefer **Bridged** or port-forwarded NAT).
* ✅ Update `/etc/hosts` on your host machine to point domain to VM IP.

### ❌ Nginx returns 502 Bad Gateway

* Gunicorn might not be running or listening correctly.
* Check Gunicorn logs or use `ps aux | grep gunicorn` to verify it's active.

### 🔁 Flask app changes not reflected

* Restart Gunicorn after making changes:

  ```bash
  pkill gunicorn
  gunicorn --bind 127.0.0.1:8000 wsgi:application
  ```

---

## Future Improvements

* ✅ Add database support (e.g., SQLite, PostgreSQL)
* ✅ Implement user authentication and authorization
* ✅ Add error logging and debug middleware
* ✅ Containerize the app with Docker + Docker Compose
* ✅ Automate startup via systemd service for Gunicorn

---

## License

MIT License — see [LICENSE](LICENSE) for details.

---

## Want to add more?

Let me know if you'd like help generating:

* `wsgi.py`
* `runserver.py`
* `gunicorn.service` for `systemd`
* `Dockerfile` / `docker-compose.yml`

---

**Happy coding! 🚀**
