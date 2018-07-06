# подключаю переменные среды от композера
include ./docker/.env
export $(shell sed 's/=.*//' ./docker/.env)

# проверка наличия переменной с именем пользователя
ifeq ($(USER_NAME),)
  $(error USER_NAME is not set)
endif

# сборка образов, всех сразу или отдельно
.PHONY: build build_src build_ui build_comment build_post build_prometheus build_mongodb_exporter build_cloudprober build_alertmanager build_grafana build_autoheal build_fluentd
build: build_src build_prometheus build_mongodb_exporter build_cloudprober build_alertmanager build_grafana build_autoheal build_fluentd
build_src: build_ui build_comment build_post 
build_ui:
	cd src/ui && bash docker_build.sh
build_ui_multistage:
	cd src/ui ;\
	echo `git show --format="%h" HEAD | head -1` > build_info.txt ;\
	echo `git rev-parse --abbrev-ref HEAD` >> build_info.txt ;\
	docker build -f Dockerfile.multistage -t $(USER_NAME)/ui . 
build_comment:
	cd src/comment && bash docker_build.sh
build_comment_multistage:
	cd src/comment ;\
	echo `git show --format="%h" HEAD | head -1` > build_info.txt ;\
	echo `git rev-parse --abbrev-ref HEAD` >> build_info.txt ;\
	docker build -f Dockerfile.multistage -t $(USER_NAME)/comment . 

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
build_grafana:
	cd monitoring/grafana && docker build --build-arg GRAFANA_VERSION=$(GRAFANA_VERSION) -t $(USER_NAME)/grafana:$(GRAFANA_VERSION) .
build_autoheal:
	cd monitoring/autoheal && docker build  -t $(USER_NAME)/autoheal:latest .

build_fluentd:
	cd logging/fluentd && docker build --build-arg FLUENTD_VERSION=$(FLUENTD_VERSION)  -t $(USER_NAME)/fluentd:$(FLUENTD_VERSION) .


# заливка образов в репозиторий, требуется предварителньо залогиниться
.PHONY: check_login push push_ui push_comment push_post push_prometheus push_mongodb_exporter push_cloudprober push_alertmanager push_grafana
push: check_login push_ui push_comment push_post push_prometheus push_mongodb_exporter push_cloudprober push_alertmanager push_grafana
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
push_grafana: check_login
	docker push $(USER_NAME)/grafana:$(GRAFANA_VERSION)
push_autoheal: check_login
	docker push $(USER_NAME)/autoheal:latest

# запуск и остановка
.PHONY: up down  stop restart
up:
	cd docker && docker-compose up -d
down:
	cd docker && docker-compose down
stop:
	cd docker && docker-compose stop
stop_post:
	cd docker && docker-compose stop post
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
log_mon:
	cd docker && docker-compose -f docker-compose-monitoring.yml logs --follow 

.PHONY: up_ah down_ah
up_ah:
	cd monitoring/autoheal && docker-compose up -d
down_ah:
	cd monitoring/autoheal && docker-compose down
log_ah:
	cd monitoring/autoheal && docker-compose logs --follow 

.PHONY: up_log down_log log_log
up_log:
	cd docker && docker-compose -f docker-compose-logging.yml up -d
down_log:
	cd docker && docker-compose -f docker-compose-logging.yml down
log_log:
	cd docker && docker-compose -f docker-compose-logging.yml logs --follow 

.PHONY: up_net down_net
up_net:
	cd docker && docker-compose -f docker-compose-net.yml up -d
down_net:
	cd docker && docker-compose -f docker-compose-net.yml down


# инфраструктура
.PHONY: machine firewall
machine:
	docker-machine create \
	--driver google \
	--google-project $(GOOGLE_PROJECT_ID) \
	--google-disk-size 20 \
	--google-machine-image https://www.googleapis.com/compute/v1/projects/ubuntu-os-cloud/global/images/family/ubuntu-1604-lts \
	--google-machine-type n1-standard-1 \
	--google-zone europe-west4-b \
	--google-scopes=\
	https://www.googleapis.com/auth/devstorage.read_only,\
	https://www.googleapis.com/auth/monitoring,\
	https://www.googleapis.com/auth/logging.write,\
	https://www.googleapis.com/auth/monitoring.write,\
	https://www.googleapis.com/auth/pubsub,\
	https://www.googleapis.com/auth/service.management.readonly,\
	https://www.googleapis.com/auth/servicecontrol,\
	https://www.googleapis.com/auth/trace.append \
	--engine-opt experimental=true \
	--engine-opt metrics-addr=0.0.0.0:9323 \
	docker-host
	docker-machine ssh docker-host gcloud auth list
	docker-machine ip docker-host
static_ip:
	gcloud compute instances delete-access-config docker-host --access-config-name "external-nat" 
	gcloud compute instances add-access-config docker-host --access-config-name "external-nat" --address $(GOOGLE_STATIC_IP)
	docker-machine regenerate-certs docker-host

.PHONY: firewall_puma firewall_mon firewall_logging firewall_prom firewall_cadvisor firewall_grafana firewall_alertmanager 
.PHONY: firewall_docker_metrics firewall_stackdriver firewall_awx firewall_logging
firewall: firewall_puma firewall_mon firewall_logging 
# правило дял приложения
firewall_puma:
	gcloud compute firewall-rules create puma-default --allow tcp:9090
# правила дял сервисов мониторинга
firewall_mon: firewall_prom firewall_cadvisor firewall_grafana firewall_alertmanager firewall_docker_metrics firewall_stackdriver firewall_awx
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
firewall_stackdriver:
	gcloud compute firewall-rules create stackdriver-exporter-default --allow tcp:9255
firewall_awx:
	gcloud compute firewall-rules create awx-default --allow tcp:8052
# правила для логинга
firewall_logging:
	gcloud compute firewall-rules create allow-tcp-5601-default --allow tcp:5601
	gcloud compute firewall-rules create allow-tcp-9411-default --allow tcp:9411


.PHONY: test_env clean clean_all
test_env:
	env | sort

# очистка системы
clean:
	docker system prune --all

clean_all:
	docker system prune --all --volumes

# проверка алерат в слак
alert:
	curl -X POST -H 'Content-type: application/json' \
	--data '{"text":"Checking send alert to slack.\n Username: $(USER_NAME)  Channel: $(SLACK_CHANNEL)"}' \
 	$(SLACK_API_URL)

# заполнение AWX данными для работы autoheal. Требуется настройка tower-cli
.PHONY: populate_awx
populate_awx:
	echo "host=$(TOWER_HOST) username=$(TOWER_USERNAME) password=$(TOWER_PASSWORD)" > monitoring/autoheal/ansible/playbooks/tower_cli.cfg
	ansible-playbook -i "localhost," -c local monitoring/autoheal/ansible/playbooks/awx-autoheal.yml

.PHONY: kube_deploy_reddit kube_deploy_mongo kube_deploy_post kube_deploy_comment kube_deploy_mongo
k8s_deploy_reddit: k8s_deploy_mongo k8s_deploy_post k8s_deploy_comment k8s_deploy_ui
k8s_deploy_post:
	cd kubernetes/reddit && envsubst < post-deployment.yml | kubectl apply -f -
k8s_deploy_comment:
	cd kubernetes/reddit && envsubst < comment-deployment.yml | kubectl apply -f -
k8s_deploy_mongo:
	cd kubernetes/reddit && envsubst < mongo-deployment.yml | kubectl apply -f -
k8s_deploy_ui:
	cd kubernetes/reddit && envsubst < ui-deployment.yml | kubectl apply -f -


k8s_install_thw:
	cd kubernetes/ansible && ansible-playbook -i inventory.yml install_k8s_thw_playbook.yml

k8s_clean_thw:
	cd kubernetes/ansible && ansible-playbook -i inventory.yml cleanup_k8s_thw_playbook.yml

k8s_utils:
	cd kubernetes/ansible && ansible-playbook -i inventory.yml --ask-become-pass kubectl.yml

k8s_terraform:
	cd kubernetes/terraform && terraform apply
k8s_terraform_destroy:
	cd kubernetes/terraform && terraform destroy
k8s_helm_init:
	kubectl apply -f kubernetes/tiller/tiller.yml
	helm init --service-account tiller
	kubectl get pods -n kube-system --selector app=helm
k8s_helm_gitlab:
	helm install --name gitlab --namespace dev   kubernetes/Charts/gitlab-omnibus -f kubernetes/Charts/gitlab-omnibus/values.yaml

k8s_nginx_ingress:
	helm install stable/nginx-ingress --name nginx
	# helm install stable/nginx-ingress --name nginx --namespace dev
k8s_prometheus:
	cd kubernetes/Charts/prometheus && helm upgrade prom . -f custom_values.yaml --install

k8s_reddit:
	cd kubernetes/Charts/reddit && helm upgrade reddit-test . --install
	cd kubernetes/Charts/reddit && helm upgrade production --namespace production . --install
	cd kubernetes/Charts/reddit && helm upgrade staging --namespace staging . --install

k8s_grafana:
	helm upgrade --install grafana stable/grafana  \
	--set "service.type=NodePort" \
	--set "ingress.enabled=true" \
	--set "ingress.hosts={reddit-grafana}"
	kubectl get secret --namespace default grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo
