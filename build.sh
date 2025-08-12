# Build image
docker build -t python-mvc .

# Run container in background, map port 3000
# Remember to update Dockerfile if you change ports
docker run -d --name mvc-app -p 3000:3000 python-mvc
