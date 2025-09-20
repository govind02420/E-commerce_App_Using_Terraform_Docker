#!/bin/bash
set -e
exec > >(tee /var/log/userdata.log|logger -t userdata -s 2>/dev/console) 2>&1

# Basic deps
apt-get update -y
apt-get install -y apt-transport-https ca-certificates curl software-properties-common jq

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# ensure ubuntu user in docker group
usermod -aG docker ubuntu || true

# start docker
systemctl enable docker
systemctl start docker

# wait for docker
until systemctl is-active --quiet docker; do
  echo "Waiting for docker..."
  sleep 2
done

# Docker Hub login (if password provided)
if [ -n "${dockerhub_password}" ]; then
  echo "${dockerhub_password}" | docker login -u "${dockerhub_username}" --password-stdin || true
fi

# create network (ignore if exists)
docker network create ecommerce-net 2>/dev/null || true

# prepare mongo data dir
MONGO_DATA_DIR="/home/ubuntu/mongo-data"
mkdir -p "${MONGO_DATA_DIR}"
chown -R 999:999 "${MONGO_DATA_DIR}" || true

# run mongo container
docker pull mongo:6.0
docker rm -f ecommerce-mongo 2>/dev/null || true
docker run -d --name ecommerce-mongo --network ecommerce-net --restart unless-stopped \
  -v "${MONGO_DATA_DIR}:/data/db" -e MONGO_INITDB_DATABASE=ecommerce mongo:6.0

# give mongo a moment to initialize
sleep 10

# Pull Docker images
docker pull "${frontend_image}"
docker pull "${user_service_image}"
docker pull "${product_service_image}"
docker pull "${cart_service_image}"
docker pull "${order_service_image}"

# Short pause so pulled images are ready
sleep 3

# Run Docker containers (remove existing containers by container name)
# Frontend
docker rm -f frontend 2>/dev/null || true
docker run -d --name frontend --network ecommerce-net --restart unless-stopped \
  -p 3000:80 "${frontend_image}"

# User Service
docker rm -f user-service 2>/dev/null || true
docker run -d --name user-service --network ecommerce-net --restart unless-stopped \
  -p 3001:3001 -e MONGODB_URI=mongodb://ecommerce-mongo:27017/ecommerce_users \
  "${user_service_image}"

# Product Service
docker rm -f product-service 2>/dev/null || true
docker run -d --name product-service --network ecommerce-net --restart unless-stopped \
  -p 3002:3002 -e MONGODB_URI=mongodb://ecommerce-mongo:27017/ecommerce_products \
  "${product_service_image}"

# Cart Service
docker rm -f cart-service 2>/dev/null || true
docker run -d --name cart-service --network ecommerce-net --restart unless-stopped \
  -p 3003:3003 -e PRODUCT_SERVICE_URL=http://product-service:3002 \
  -e MONGODB_URI=mongodb://ecommerce-mongo:27017/ecommerce_cart \
  "${cart_service_image}"

# Order Service
docker rm -f order-service 2>/dev/null || true
docker run -d --name order-service --network ecommerce-net --restart unless-stopped \
  -p 3004:3004 -e MONGODB_URI=mongodb://ecommerce-mongo:27017/ecommerce_orders \
  "${order_service_image}"

# quick status
docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"
echo "userdata done"
