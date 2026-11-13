.PHONY: up down restart logs test-db help

help:
	@echo "Astra Mind Automation Engine Commands:"
	@echo "  make up       - Start n8n container"
	@echo "  make down     - Stop container"
	@echo "  make restart  - Restart container"
	@echo "  make logs     - Tail container execution logs"

up:
	docker compose up -d
	@echo "Astra Mind is ready at http://localhost:5678"

down:
	docker compose down

restart:
	docker compose restart

logs:
	docker compose logs -f --tail=100
