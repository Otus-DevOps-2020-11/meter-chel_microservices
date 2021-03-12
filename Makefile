#Envs
USER_NAME=ge2rg312qe
PASS=~/$(USER_NAME).pwd
DOCKER_TAG=latest
SRC_TAG=logging


# Builds
build:: build-prometheus build-alertmanager build-ui build-comment build-post

build-prometheus::
	cd monitoring/prometheus && \
	docker build -t $(USER_NAME)/prometheus:$(DOCKER_TAG) .
	echo
build-alertmanager::
	cd monitoring/alertmanager && \
	docker build -t $(USER_NAME)/alertmanager:$(DOCKER_TAG) .
build-ui::
	cd src/ui && \
	USER_NAME=$(USER_NAME) bash docker_build.sh
build-comment::
	cd src/comment && \
	USER_NAME=$(USER_NAME) bash docker_build.sh
build-post::
	cd src/post-py && \
	USER_NAME=$(USER_NAME) bash docker_build.sh


#Push
push:: push-prometheus push-alertmanager push-ui push-comment push-post docker-logout

push-prometheus:: build-prometheus docker-login
	docker push $(USER_NAME)/prometheus:$(DOCKER_TAG)
push-alertmanager:: build-alertmanager docker-login
	docker push $(USER_NAME)/alertmanager:$(DOCKER_TAG)
push-ui:: build-ui docker-login
	docker push $(USER_NAME)/ui:$(SRC_TAG)
push-comment:: build-comment docker-login
	docker push $(USER_NAME)/comment:$(SRC_TAG)
push-post:: build-post docker-login
	docker push $(USER_NAME)/post:$(SRC_TAG)

# Login
docker-login::
	cat $(PASS) | docker login -u $(USER_NAME) --password-stdin

docker-logout::
	docker logout

up:: build docker-compose-up docker-compose-ps

# Create containers

docker-compose-up::
	cd docker && \
	docker-compose up -d && \
	docker-compose -f docker-compose-monitoring.yml up -d

# Show containers
docker-compose-ps::
	cd docker && \
	docker-compose ps

# Stop and kill
clean:: docker-compose-down

docker-compose-down::
	cd docker && \
	docker-compose -f docker-compose-monitoring.yml down -v --remove-orphans && \
	docker-compose down -v --remove-orphans
