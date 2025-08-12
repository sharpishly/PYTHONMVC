#!/bin/bash

# Build the image (name it python-mvc)
docker build -t python-mvc .

# Run the container mapping port 8000 on host to 8000 in container
docker run -p 8000:8000 python-mvc
