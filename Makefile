## You can follow the steps below in order to get yourself a local ODC.
## Start by running `setup` then you should have a system that is fully configured

.PHONY: help setup up down clean

BBOX := 20,39,25,41

help: ## Print this help
	@grep -E '^##.*$$' $(MAKEFILE_LIST) | cut -c'4-'
	@echo
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-10s\033[0m %s\n", $$1, $$2}'

setup: build up init product index explorer ## Run a full local/development setup
update: build up ## Run a full local/development setup

up: ## 1. Bring up your Docker environment
	sudo docker-compose up -d postgres
	sudo docker-compose run checkdb
	sudo docker-compose up -d explorer
	sudo docker-compose up -d openeo_odc_driver

init: ## 2. Prepare the database
	sudo docker-compose exec -T openeo_odc_driver datacube -v system init

product: ## 3. Add a product definition for Sentinel-2
	sudo docker-compose exec -T openeo_odc_driver wget https://raw.githubusercontent.com/digitalearthafrica/config/master/products/esa_s2_l2a.odc-product.yaml
	sudo docker-compose exec -T openeo_odc_driver datacube product add esa_s2_l2a.odc-product.yaml

index: ## 4. Index some data (Change extents with BBOX='<left>,<bottom>,<right>,<top>')
	sudo docker-compose exec -T openeo_odc_driver bash -c "stac-to-dc --bbox='$(BBOX)' --catalog-href='https://earth-search.aws.element84.com/v0/' --collections='sentinel-s2-l2a-cogs' --datetime='2023-01-01/2023-07-01'"

explorer: ## 5. Prepare the explorer
	sudo docker-compose exec -T explorer cubedash-gen --init --all

down: ## Bring down the system
	sudo docker-compose down

build: ## Rebuild the base image
	sudo docker-compose pull
	sudo docker-compose build

shell: ## Start an interactive shell
	sudo docker-compose exec openeo_odc_driver bash

clean: ## Delete everything
	sudo docker-compose down --rmi all -v

logs: ## Show the logs from the stack
	sudo docker-compose logs --follow
