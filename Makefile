#!/usr/bin/make
# Makefile readme (ru): <http://linux.yaroslavl.ru/docs/prog/gnu_make_3-79_russian_manual.html>
# Makefile readme (en): <https://www.gnu.org/software/make/manual/html_node/index.html#SEC_Contents>

SHELL = /bin/sh

# Important: Local images naming should be in docker-compose naming style
APP_IMAGE_DOCKERFILE = ./docker/app/Dockerfile
APP_IMAGE_CONTEXT = ./
APP_CONTAINER_CLI_NAME := php-cli
APP_CONTAINER_NAME := app
NODE_CONTAINER_NAME := node

USER := daniil:daniil

docker_bin := $(shell command -v docker 2> /dev/null)
docker_compose_bin := $(shell command -v docker-compose 2> /dev/null)


# ---------------------------------------------------------------------------------------------------------------------

clean: ## Remove images from local registry
	-$(docker_compose_bin) down -v
	$(foreach image,$(all_images),$(docker_bin) rmi -f $(image);)

# --- [ Development tasks ] -------------------------------------------------------------------------------------------

---------------: ## ---------------
build: ## Build
	$(docker_compose_bin) build

up: ## Start all containers (in background) for development
	$(docker_compose_bin) up -d

down: ## Stop all started for development containers
	$(docker_compose_bin) down

restart: up ## Restart all started for development containers
	$(docker_compose_bin) restart

shell: up ## Start shell into application container
	$(docker_compose_bin) exec "$(APP_CONTAINER_NAME)" /bin/sh

install: up ## Install application dependencies into application container
	$(docker_compose_bin) exec "$(APP_CONTAINER_NAME)" composer install --no-interaction --ansi --no-suggest
	$(docker_compose_bin) run --rm "$(NODE_CONTAINER_NAME)" npm install

watch: up ## Start watching assets for changes (node)
	$(docker_compose_bin) run --rm "$(NODE_CONTAINER_NAME)" npm run watch

init: install ## Make full application initialization (install, seed, build assets, etc)
	$(docker_compose_bin) exec "$(APP_CONTAINER_NAME)" php artisan migrate --force --no-interaction -vvv
	$(docker_compose_bin) exec "$(APP_CONTAINER_NAME)" php artisan db:seed --force -vvv
	$(docker_compose_bin) run --rm "$(NODE_CONTAINER_NAME)" npm run dev

migrate: up ## Make full application initialization (install, seed, build assets, etc)
	$(docker_compose_bin) exec "$(APP_CONTAINER_NAME)" php artisan migrate --force --no-interaction -vvv

seed: up ## Make full application initialization (install, seed, build assets, etc)
	$(docker_compose_bin) exec "$(APP_CONTAINER_NAME)" php artisan db:seed --force -vvv

test: up ## Execute application tests
	$(docker_compose_bin) exec "$(APP_CONTAINER_NAME)" php -v
	$(docker_compose_bin) exec "$(APP_CONTAINER_NAME)" composer -V

perm:
	sudo chown -R daniil storage bootstrap/cache node_modules resources
	sudo chmod -R ug+rwx storage bootstrap/cache node_modules resources
	if [ -d "node_modules" ]; then sudo chown -R daniil node_modules -R; fi
	if [ -d "node_modules" ]; then sudo chmod -R ug+rwx node_modules -R; fi
	if [ -d "public/build" ]; then sudo chown -R daniil public/build -R; fi
	if [ -d "public/build" ]; then sudo chmod -R ug+rwx public/build -R; fi

test-unit: up ## Execute PHPUnit test
	$(docker_compose_bin) exec "$(APP_CONTAINER_NAME)" vendor/bin/phpunit

assets-install: up
	$(docker_compose_bin) exec node yarn install

assets-rebuild: up
	$(docker_compose_bin) exec node npm rebuild node-sass --force

assets-dev: up
	$(docker_compose_bin) exec node yarn run dev

assets-watch: up
	$(docker_compose_bin) exec node yarn run watch

queue: up
	$(docker_compose_bin) exec app php artisan queue:work
