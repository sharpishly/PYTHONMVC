FROM python:3.11-slim

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

WORKDIR /app

# Install system dependencies (optional: for building Python packages)
RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    curl \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt /app/

RUN pip install --no-cache-dir -r requirements.txt \
    && pip install --no-cache-dir gunicorn

COPY . /app/

EXPOSE 8000

# Directly run Gunicorn instead of relying on start.sh's venv activation
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "wsgi:application"]

