# After changing BASE_IMAGE_NAME, make sure to update .env
BASE_IMAGE_NAME=myproject

PROD_IMAGE_NAME=$(BASE_IMAGE_NAME)-prod
UV_CACHE_DIR=`command -v uv >/dev/null 2>&1 && uv cache dir || echo '.uv'`

.PHONY: env build deps deps-update clear-build dev stop bash sudo-bash run-bash run-sudo-bash lint test mypy check prod-build prod-run prod-run-bash prod-run-sudo-bash prod-export-image prod-import-image

# Building and dependencies
env:
	if [ ! -d "$(UV_CACHE_DIR)" ]; then mkdir "$(UV_CACHE_DIR)"; fi
	if [ ! -f ".env" ]; then echo "BASE_IMAGE_NAME=${BASE_IMAGE_NAME}\nUV_CACHE_DIR=${UV_CACHE_DIR}" > .env; fi
build: env
	docker compose build \
		--build-arg GROUP_ID=`id -g` \
		--build-arg USER_ID=`id -u`
deps: build
	docker compose run --rm jupyter uv sync
deps-update: build
	docker compose run --rm jupyter uv lock --upgrade
clear-build:
	docker compose rm

# Running the development environment
dev: deps notebook-sync
	docker compose up
stop:
	docker compose stop

# Starting a shell in a Docker container (must be run with
# a `service=[app|jupyter]` argument)
check-service:
	@if [ -z "$(service)" ]; then echo "Please set service=[app|jupyter]"; exit 1; fi
bash: check-service
	docker compose exec $(service) /bin/bash
sudo-bash: check-service
	docker compose exec --user root $(service) /bin/bash
run-bash: check-service
	docker compose run --rm $(service) /bin/bash
run-sudo-bash: check-service
	docker compose run --user root --rm $(service) /bin/bash

# Python module utilities
lint:
	docker compose run --rm jupyter uv run flake8 src/* script_notebooks/*
test:
	docker compose run --rm jupyter uv run pytest \
		--cov="src" \
		--cov-report="html:tests/coverage" \
		--cov-report=term ;
mypy:
	docker compose run --rm jupyter uv run mypy src/* script_notebooks/*
check: lint mypy test

# Notebook utilities
notebook-export:
	docker compose run --rm --workdir /home/coder/src/notebooks jupyter uv run \
		jupyter nbconvert --template nbconvert_tpl --to html --output-dir export \
		*.ipynb
notebook-sync:
	docker compose run --rm jupyter /bin/bash -c "shopt -s globstar && uv run jupytext --sync notebooks/**/*.ipynb"

# Production/deployable app
prod-build: env
	@echo "Clearing output from app notebooks"
	docker compose run --rm jupyter app/clean-notebooks.sh
	docker build \
		--progress=plain \
		--build-arg GROUP_ID=`id -g` \
		--build-arg USER_ID=`id -u` \
		--target prod_image -t $(PROD_IMAGE_NAME) .
prod-run: prod-build
	docker run --name $(BASE_IMAGE_NAME)-app-prod -p 127.0.0.1:8866:8866 --rm $(PROD_IMAGE_NAME)
prod-run-bash:
	docker run -it --rm $(PROD_IMAGE_NAME) /bin/bash
prod-run-sudo-bash:
	docker run -u root -it --rm $(PROD_IMAGE_NAME) /bin/bash
prod-export-image: prod-build
	mkdir -p app/images
	docker save -o "app/images/$(PROD_IMAGE_NAME).image" $(PROD_IMAGE_NAME)
prod-import-image:
	docker load --input "app/images/$(PROD_IMAGE_NAME).image"
