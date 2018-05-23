USER_NAME = spinor72

.PHONY: build build_ui build_comment build_post build_prometheus build_mongodb_exporter
build: build_ui build_comment build_post build_prometheus build_mongodb_exporter
build_ui:
	cd src/ui && bash docker_build.sh
build_comment:
	cd src/comment && bash docker_build.sh
build_post:
	cd src/post-py && bash docker_build.sh
build_prometheus:
	cd monitoring/prometheus && docker build -t $(USER_NAME)/prometheus .
build_mongodb_exporter:
	cd monitoring/prometheus-mongodb-exporter && docker build -t $(USER_NAME)/prometheus-mongodb-exporter .

.PHONY: push push_ui push_comment push_post push_prometheus push_mongodb_exporter
push: push_ui push_comment push_post push_prometheus push_mongodb_exporter
push_ui:
	docker push $(USER_NAME)/ui
push_comment:
	docker push $(USER_NAME)/comment
push_post:
	docker push $(USER_NAME)/post
push_prometheus:
	docker push $(USER_NAME)/prometheus
push_mongodb_exporter:
	docker push $(USER_NAME)/prometheus-mongodb-exporter

up:
	cd docker && docker-compose up -d
stop:
	cd docker && docker-compose stop
restart:  stop up
