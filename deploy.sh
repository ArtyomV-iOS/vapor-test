#!/bin/bash

# Vapor Test API Deployment Script
# This script builds and deploys the Vapor application using Docker

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
IMAGE_NAME="vapor-test-api"
CONTAINER_NAME="vapor-test-api-container"
NETWORK_NAME="vapor-test-network"

echo -e "${GREEN}🚀 Starting Vapor Test API Deployment${NC}"

# Function to print colored output
print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    print_error "Docker is not running. Please start Docker and try again."
    exit 1
fi

# Stop and remove existing containers
print_status "Cleaning up existing containers..."
docker-compose down --remove-orphans 2>/dev/null || true

# Remove old images
print_status "Removing old images..."
docker rmi $IMAGE_NAME:latest 2>/dev/null || true

# Build the application
print_status "Building Docker image..."
docker-compose build --no-cache

# Create network if it doesn't exist
print_status "Setting up Docker network..."
docker network create $NETWORK_NAME 2>/dev/null || true

# Start the services
print_status "Starting services..."
docker-compose up -d

# Wait for database to be ready
print_status "Waiting for database to be ready..."
sleep 10

# Run migrations
print_status "Running database migrations..."
docker-compose run --rm migrate

# Check if the application is running
print_status "Checking application health..."
sleep 5

if curl -f http://localhost:8080/health > /dev/null 2>&1; then
    print_status "Application is running successfully!"
    echo -e "${GREEN}🌐 API is available at: http://localhost:8080${NC}"
    echo -e "${GREEN}📊 Health check: http://localhost:8080/health${NC}"
    echo -e "${GREEN}🗄️  Database is available at: localhost:5432${NC}"
else
    print_error "Application failed to start properly"
    echo "Checking logs..."
    docker-compose logs app
    exit 1
fi

print_status "Deployment completed successfully!"

# Show running containers
echo ""
print_status "Running containers:"
docker-compose ps

echo ""
print_warning "To stop the application, run: docker-compose down"
print_warning "To view logs, run: docker-compose logs -f" 