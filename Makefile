# подключаю переменные среды от композера
include ./docker/.env
export $(shell sed 's/=.*//' ./docker/.env)

# проверка наличия переменной с именем пользователя
ifeq ($(USER_NAME),)
  $(error USER_NAME is not set)
endif

# сборка образов, всех сразу или отдельно
.PHONY: build build_ui build_comment build_post build_prometheus build_mongodb_exporter build_cloudprober build_alertmanager
build: build_ui build_comment build_post build_prometheus build_mongodb_exporter build_cloudprober build_alertmanager
build_ui:
	cd src/ui && bash docker_build.sh
build_comment:
	cd src/comment && bash docker_build.sh
build_post:
	cd src/post-py && bash docker_build.sh
build_prometheus:
	cd monitoring/prometheus && docker build -t $(USER_NAME)/prometheus .
build_mongodb_exporter:
	cd monitoring/exporters/percona-mongodb-exporter && docker build --build-arg PERCONA_MONGODB_EXPORTER_VERSION=$(PERCONA_MONGODB_EXPORTER_VERSION) -t $(USER_NAME)/percona-mongodb-exporter:$(PERCONA_MONGODB_EXPORTER_VERSION) .
build_cloudprober:
	cd monitoring/exporters/google-cloudprober && docker build --build-arg CLOUDPROBER_VERSION=$(CLOUDPROBER_VERSION) -t $(USER_NAME)/google-cloudprober:$(CLOUDPROBER_VERSION) .
build_alertmanager:
	cd monitoring/alertmanager && docker build --build-arg ALERTMANAGER_VERSION=$(ALERTMANAGER_VERSION) -t $(USER_NAME)/alertmanager:$(ALERTMANAGER_VERSION) .

# заливка образов в репозиторий, требуется предварителньо залогиниться
.PHONY: check_login push push_ui push_comment push_post push_prometheus push_mongodb_exporter push_cloudprober push_alertmanager
push: check_login push_ui push_comment push_post push_prometheus push_mongodb_exporter push_cloudprober push_alertmanager
check_login:
	if grep -q 'auths": {}' ~/.docker/config.json ; then echo "Please login to Docker HUb first" && exit 1; fi
push_ui: check_login
	docker push $(USER_NAME)/ui
push_comment: check_login
	docker push $(USER_NAME)/comment
push_post: check_login
	docker push $(USER_NAME)/post
push_prometheus: check_login
	docker push $(USER_NAME)/prometheus
push_mongodb_exporter: check_login
	docker push $(USER_NAME)/percona-mongodb-exporter:$(PERCONA_MONGODB_EXPORTER_VERSION)
push_cloudprober: check_login
	docker push $(USER_NAME)/google-cloudprober:$(CLOUDPROBER_VERSION)
push_alertmanager: check_login
	docker push $(USER_NAME)/alertmanager:$(ALERTMANAGER_VERSION)

# запуск и остановка
.PHONY: up down  stop restart
up:
	cd docker && docker-compose up -d
down:
	cd docker && docker-compose down
stop:
	cd docker && docker-compose stop
log:
	cd docker && docker-compose logs --follow
restart:  down up
reload: stop up

# запуск и остановка мониторинга
.PHONY: up_mon down_mon
up_mon:
	cd docker && docker-compose -f docker-compose-monitoring.yml up -d
down_mon:
	cd docker && docker-compose -f docker-compose-monitoring.yml down


# инфраструктура
.PHONY: machine firewall docker_opt
machine:
	docker-machine create --driver google --google-disk-size 20 \
	--google-machine-image https://www.googleapis.com/compute/v1/projects/ubuntu-os-cloud/global/images/family/ubuntu-1604-lts \
	--google-machine-type n1-standard-1 \
	--google-zone europe-west4-b \
	--engine-opt experimental=true \
	--engine-opt metrics-addr=0.0.0.0:9323 \
	docker-host

docker_opt:
	docker-machine create -d google \
	--engine-opt experimental=true \
	--engine-opt metrics-addr=0.0.0.0:9323 \
	docker-host


firewall: firewall_puma firewall_prom firewall_cadvisor firewall_grafana
firewall_puma:
	gcloud compute firewall-rules create puma-default --allow tcp:9090
firewall_prom:
	gcloud compute firewall-rules create prometheus-default --allow tcp:9292
firewall_cadvisor:
	gcloud compute firewall-rules create cadvisor-default --allow tcp:8080
firewall_grafana:
	gcloud compute firewall-rules create grafana-default --allow tcp:3000
firewall_alertmanager:
	gcloud compute firewall-rules create alertmanager-default --allow tcp:9093
firewall_docker_metrics:
	gcloud compute firewall-rules create docker-metrics-default --allow tcp:9323

.PHONY: test_env clean clean_all
test_env:
	env | sort

# очистка системы
clean:
	docker system prune --all

clean_all:
	docker system prune --all --volumes


alert:
	curl -X POST -H 'Content-type: application/json' \
	--data '{"text":"Checking send alert to slack.\n Username: $(USER_NAME)  Channel: $(SLACK_CHANNEL)"}' \
 	$(SLACK_API_URL)

config:
	~/proj/go/frep --overwrite ./monitoring/alertmanager/config.yml.in
