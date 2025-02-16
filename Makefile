SERVICE_NAME=flask-messenger-api

build: build

run: up

start: restart

stop: down

log: logs

build: 
	@echo "Building $(SERVICE_NAME)..."
	docker-compose build

# Bring the services up
up:
	@echo "Starting $(SERVICE_NAME)..."
	docker-compose up -d 

# Bring the services down
down:
	@echo "Stopping $(SERVICE_NAME)..."
	docker-compose down

restart: down up

rebuild:
	docker-compose down --volumes --remove-orphans
	docker-compose up --build

logs:
	docker logs flask-messenger-api