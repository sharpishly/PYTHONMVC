FROM python:3.11-slim

# Environment variables for Python
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

WORKDIR /app

# Install system dependencies (optional: curl for debugging)
RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy and install dependencies
COPY requirements.txt /app/
RUN pip install --no-cache-dir -r requirements.txt \
    && pip install --no-cache-dir gunicorn

# Copy the application code
COPY . /app/

# Expose port 3000 for Gunicorn
EXPOSE 3000

# Run Gunicorn directly without venv
CMD ["gunicorn", "--bind", "0.0.0.0:3000", "wsgi:application"]
