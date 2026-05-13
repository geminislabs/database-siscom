# ============================================================
# Uso: make <target>
# ** ONLY FOR DEVELOPMENT PURPOSES **
# ============================================================

-include .env

COMPOSE      = docker compose
DB_CONTAINER = postgres
DB_USER      := $(POSTGRES_USER)
DB_NAME      := $(POSTGRES_DB)
DB_PORT      := 5432

.PHONY: help up down reset logs psql init seed status wait

help:
	@echo ""
	@echo "  SISCOM Database — comandos disponibles:"
	@echo ""
	@echo "  make up      Levanta Postgres"
	@echo "  make down    Detiene los contenedores"
	@echo "  make reset   Borra volúmenes y reinicia desde cero"
	@echo "  make logs    Muestra los logs de Postgres"
	@echo "  make psql    Abre una sesión psql interactiva"
	@echo "  make status  Estado de los contenedores"
	@echo "  make init    Ejecuta todos los scripts de initdb/ en orden"
	@echo "  make seed    Ejecuta solo initdb/04_seed.sql"
	@echo ""

## ── Ciclo de vida ────────────────────────────────────────
up:
	@echo "Levantando Postgres..."
	@docker network inspect siscom-network >/dev/null 2>&1 || docker network create siscom-network
	$(COMPOSE) up -d postgres --remove-orphans
	@$(MAKE) -s wait
	@echo "Postgres listo en localhost:$(DB_PORT)  |  DB: $(DB_NAME)  Usuario: $(DB_USER)"

down:
	@echo "Deteniendo contenedores..."
	$(COMPOSE) down

reset:
	@echo "Eliminando volúmenes y reiniciando..."
	$(COMPOSE) down -v
	@docker network inspect siscom-network >/dev/null 2>&1 || docker network create siscom-network
	$(COMPOSE) up -d postgres
	@$(MAKE) -s wait
	@echo "Base de datos reconstruida"

## ── Herramientas ─────────────────────────────────────────
logs:
	$(COMPOSE) logs -f postgres

psql:
	docker exec -it $(DB_CONTAINER) psql -U $(DB_USER) -d $(DB_NAME)

status:
	$(COMPOSE) ps

## ── Init: scripts de initdb/ en orden alfabético ─────────
# ***  DESTRUCTIVO — NO ejecutar contra producción ***
init:
	@echo "Ejecutando scripts de inicialización..."
	@ls initdb/*.sql 2>/dev/null | sort | while read f; do \
		echo "  -> $$f"; \
		docker exec -i $(DB_CONTAINER) psql -U $(DB_USER) -d $(DB_NAME) < $$f || exit 1; \
	done
	@echo "Init completado"

## ── Seed manual ──────────────────────────────────────────
seed:
	@echo "Ejecutando seed..."
	docker exec -i $(DB_CONTAINER) psql -U $(DB_USER) -d $(DB_NAME) < initdb/04_seed.sql
	@echo "Seed completado"

debug:
	@echo "DB_USER='$(DB_USER)'"
	@echo "DB_NAME='$(DB_NAME)'"
	@echo "DB_PORT='$(DB_PORT)'"

## ── Interno: esperar a que Postgres esté listo ───────────
wait:
	@echo "Esperando a que Postgres esté listo..."
	@for i in $$(seq 1 30); do \
		docker exec $(DB_CONTAINER) pg_isready -U $(DB_USER) -d $(DB_NAME) -q 2>/dev/null \
			&& echo "  listo" && exit 0; \
		echo "  ... intento $$i/30"; \
		sleep 2; \
	done; \
	echo "Postgres no respondio a tiempo" && exit 1