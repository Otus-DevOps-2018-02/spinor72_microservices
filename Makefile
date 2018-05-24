# подключаю переменные среды от композера
include ./docker/.env
export $(shell sed 's/=.*//' ./docker/.env)

# проверка наличия переменной с именем пользователя
ifeq ($(USER_NAME),)
  $(error USER_NAME is not set)
endif

# сборка образов, всех сразу или отдельно
.PHONY: build build_ui build_comment build_post build_prometheus build_mongodb_exporter build_cloudprober
build: build_ui build_comment build_post build_prometheus build_mongodb_exporter build_cloudprober
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

# заливка образов в репозиторий, требуется предварителньо залогиниться
.PHONY: check_login push push_ui push_comment push_post push_prometheus push_mongodb_exporter push_cloudprober
push: check_login push_ui push_comment push_post push_prometheus push_mongodb_exporter push_cloudprober
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

# инфраструктура
.PHONY: machine firewall
machine:
	docker-machine create --driver google --google-disk-size 20 \
	--google-machine-image https://www.googleapis.com/compute/v1/projects/ubuntu-os-cloud/global/images/family/ubuntu-1604-lts \
	--google-machine-type n1-standard-1 \
	--google-zone europe-west4-b \
	docker-host

firewall:
	gcloud compute firewall-rules create prometheus-default --allow tcp:9090
	gcloud compute firewall-rules create puma-default --allow tcp:9292


.PHONY: test_env clean clean_all
test_env:
	env | sort

# очистка системы
clean:
	docker system prune --all

clean_all:
	docker system prune --all --volumes
