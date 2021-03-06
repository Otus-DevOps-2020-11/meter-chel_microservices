#Envs
USER_NAME=ge2rg312qe
PASS=~/$(USER_NAME).pwd
TAG_MON=logging
TAG_LOG=logging


# Builds
build:: build-prometheus build-alertmanager build-fluentd build-comment build-post build-ui

build-prometheus::
	cd monitoring/prometheus && \
	docker build -t $(USER_NAME)/prometheus:$(TAG_MON) .
	echo
build-alertmanager::
	cd monitoring/alertmanager && \
	docker build -t $(USER_NAME)/alertmanager:$(TAG_MON) .
	echo
build-ui::
	cd src/ui && \
	USER_NAME=$(USER_NAME) bash docker_build.sh
	echo
build-comment::
	cd src/comment && \
	USER_NAME=$(USER_NAME) bash docker_build.sh
	echo
build-post::
	cd src/post-py && \
	USER_NAME=$(USER_NAME) bash docker_build.sh
	echo
build-fluentd::
	cd logging/fluentd && \
	docker build -t $(USER_NAME)/fluentd:$(TAG_LOG) .
	echo


#Push
push:: push-prometheus push-alertmanager push-fluentd push-ui push-comment push-post docker-logout

push-prometheus:: build-prometheus docker-login
	docker push $(USER_NAME)/prometheus:$(TAG_MON)
push-alertmanager:: build-alertmanager docker-login
	docker push $(USER_NAME)/alertmanager:$(TAG_MON)
push-ui:: build-ui docker-login
	docker push $(USER_NAME)/ui:logging
push-comment:: build-comment docker-login
	docker push $(USER_NAME)/comment:logging
push-post:: build-post docker-login
	docker push $(USER_NAME)/post:logging
push-fluentd:: build-fluentd docker-login
	docker push $(USER_NAME)/fluentd:$(TAG_LOG)


# Login
docker-login::
	cat $(PASS) | docker login -u $(USER_NAME) --password-stdin

docker-logout::
	docker logout

up:: build push docker-compose-up docker-compose-ps

# Create containers

docker-compose-up::
	cd docker && \
#	docker-compose up -d --build && \
	docker-compose -f docker-compose-monitoring.yml up -d && \
	docker-compose -f docker-compose-logging.yml up -d && \
	docker-compose -f docker-compose.yml up -d

# Show containers
docker-compose-ps::
	cd docker && \
	docker-compose -f docker-compose.yml ps && \
	docker-compose -f docker-compose-monitoring.yml ps && \
	docker-compose -f docker-compose-logging.yml ps

# Stop and kill
clean:: docker-compose-down

docker-compose-down::
	cd docker && \
	docker-compose -f docker-compose-logging.yml down -v --remove-orphans && \
	docker-compose -f docker-compose-monitoring.yml down -v --remove-orphans && \
	docker-compose down -v
