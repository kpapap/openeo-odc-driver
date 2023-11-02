## You can follow the steps below in order to get yourself a local ODC.
## Start by running `setup` then you should have a system that is fully configured

.PHONY: help setup up down clean

BBOX := 20,39,25,41

help: ## Print this help
	@grep -E '^##.*$$' $(MAKEFILE_LIST) | cut -c'4-'
	@echo
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-10s\033[0m %s\n", $$1, $$2}'

setup: build up init product explorer ## deleted index, it was placed before explorer - Run a full local/development setup
update: build up ## Run a full local/development setup

up: ## 1. Bring up your Docker environment
	docker-compose up -d postgres
	docker-compose run checkdb
	docker-compose up -d explorer
	docker-compose up -d openeo_odc_driver

init: ## 2. Prepare the database
	docker-compose exec -T openeo_odc_driver datacube -v system init

product: ## 3. Add a product definition for Sentinel-2
	docker-compose exec -T openeo_odc_driver wget https://datacubepublicbucket.s3.us-west-2.amazonaws.com/s2_l2a.odc-product.yaml
	docker-compose exec -T openeo_odc_driver datacube product add s2_l2a.odc-product.yaml

index: ## 4. Index some data (Change extents with BBOX='<left>,<bottom>,<right>,<top>')
	docker-compose exec -T openeo_odc_driver bash -c "stac-to-dc --bbox='$(BBOX)' --catalog-href='https://earth-search.aws.element84.com/v0/' --collections='sentinel-s2-l2a-cogs' --datetime='2023-01-01/2023-07-01'"
	docker-compose exec -T openeo_odc_driver bash -c "stac-to-dc --bbox='20,39,25,41' --catalog-href='https://earth-search.aws.element84.com/v1/' --collections='sentinel-s2-l2a' --datetime='2023-01-01/2023-07-01'"
	11/02/2023 07:57:38: WARNING: Didn't find any items, finishing.
	docker-compose exec -T openeo_odc_driver bash -c "stac-to-dc --bbox='20,39,25,41' --catalog-href='https://earth-search.aws.element84.com/v1/' --collections='sentinel-2-l1c' --datetime='2023-01-01/2023-07-01'"
	KeyError: 'sentinel:latitude_band'
	Indexing from STAC API...
	Added 0 Datasets, failed 1082 Datasets

explorer: ## 5. Prepare the explorer
	docker-compose exec -T explorer cubedash-gen --init --all

down: ## Bring down the system
	docker-compose down

build: ## Rebuild the base image
	docker-compose pull
	docker-compose build

shell: ## Start an interactive shell
	docker-compose exec openeo_odc_driver bash

clean: ## Delete everything
	docker-compose down --rmi all -v

logs: ## Show the logs from the stack
	docker-compose logs --follow
