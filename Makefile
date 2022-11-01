APP := jena-fuseki
REGION := iad
VOLUME := fuseki_data
MEMORY := 2048

.PHONY: destroy deploy ncg-dataset dogs-dataset

destroy:
	fly apps destroy $(APP) --yes

deploy:
	fly launch --copy-config --name $(APP) --no-deploy --region $(REGION)
	read -s -p "Fuseki admin password: " pwd && \
	echo $$pwd | fly secrets set ADMIN_PASSWORD=-
	fly volumes create $(VOLUME) --region iad --size 1 --no-encryption
	fly scale memory $(MEMORY)
	fly deploy

ncg-dataset: DATASET = ncg
ncg-dataset: DATAFILE = ncg.nt
ncg-dataset: DATAFILE_SOURCE = ../ncg-dataset/dataset.nt

dogs-dataset: DATASET = dogs
dogs-dataset: DATAFILE = dogs.ttl

ncg-dataset dogs-dataset:
ifdef $(DATAFILE_SOURCE)
	cp $(DATAFILE_SOURCE) dataset/$(DATAFILE)
endif
	curl \
	--user admin \
	--form $(DATAFILE)=@dataset/$(DATAFILE) \
	https://$(APP).fly.dev/$(DATASET)/data
