APP := jena-fuseki
REGION := iad
VOLUME := fuseki_data
MEMORY := 2048
DATASET := NCG
DATA := /Users/ryanshaw/Code/ncg-dataset/dataset.nt

.DEFAULT_GOAL := dataset
.PHONY: destroy deploy dataset

destroy:
	fly apps destroy $(APP) --yes

deploy:
	fly launch --copy-config --name $(APP) --no-deploy --region $(REGION)
	read -s -p "Fuseki admin password: " pwd && \
	echo $$pwd | fly secrets set ADMIN_PASSWORD=-
	fly volumes create $(VOLUME) --region iad --size 1 --no-encryption
	fly scale memory $(MEMORY)
	fly deploy

data.nt: $(DATA)
	cp $< $@

dataset: data.nt
	curl \
	--user admin \
	--data dbName=NCG \
	--data dbType=tdb2 \
	https://$(APP).fly.dev/$$/datasets
	curl \
	--user admin \
	--form $<=@$< \
	https://$(APP).fly.dev/$(DATASET)/data
