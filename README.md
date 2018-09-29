# spinor72_microservices
[![Build Status](https://travis-ci.org/Otus-DevOps-2018-02/spinor72_microservices.svg?branch=master)](https://travis-ci.org/Otus-DevOps-2018-02/spinor72_microservices)

Репозиторий для ДЗ по теме "microservices"

## ДЗ №13 Технология контейнеризации. Введение в Docker.

 - [x] Основное ДЗ
 - [x] Задание со *
 
### В процессе сделано:
Установлены пакеты для работы с контейнерами:
```
docker version 18.03.0-ce
docker-compose version 1.16.1,
docker-machine version 0.14.0
```
Изучены основные команды для `docker`:   
 `inof`, `run [-i|-d][-t]`, `ps`, `images`, `create`, `start`, `attach`, `exec`, `commit`, `inspect`, `kill`, `system df`, `rm`, `rmi` 

Записан вывод команды `docker images` в файл `docker-monolith/docker-1.log` , в который для задания * добавлено описание отличий вывода команды  `docker inspect` для образа и контейнера

### Как запустить проект:
не применимо

### Как проверить работоспособность:
не применимо

## ДЗ №14 Docker-контейнеры.

 - [x] Основное ДЗ
 - [x] Задание со *
 
### В процессе сделано:

 - Создан новый проект в GCP с названием docker;
 - С помощью пакета `docker-machine` в GCE развернут хост для работы с docker-контейнерами
 - Проверена работа изоляции ресурсов, например, опция запуска `--pid host` отключает изоляцию на уровне pid, таким образом контейнер видит все процессы системы, в отличие от запуска по-умолчанию, без такой опции
 - Создан `Dockerfile` для генерации образа с тестовым приложением.
 - Образ контейнера с тестовым приложение мсгенерирован и размещен в реестре Docker Hub под именем `spinor72/otus-reddit`
 - Проверена процедура развертывания созданного образа на docker-host из размещенного в реестре образа

Для задания со *
 - Созданы шаблоны packer для генерации образа с установленным Docker
 - Настроено создание заданного количества хостов в GCE с помощью  терраформа 
 - Созданы плейбуки ansible для установки Docker и развертывания контейнера  с тестовым приложением (используется динамическое инвентори из terraform state в бакете)

### Как запустить проект:

 - Создать контейнер

    В папке docker-monolith создать образ  командой вида, где `docker_hub_login` - ваш логин в Docker Hub
    ```
    docker build -t docker_hub_login/otus-reddit:1.0 .
    ```
    и, авторизовавшись командой `docker login` загрузить его в свой реестр на Docker Hub,
    ```
    docker push docker_hub_login/otus-reddit:1.0
    ```
    Запустить контейнер командой `docker run --name reddit -d -p 9292:9292 docker_hub_login/otus-reddit:1.0`


 - Развернуть инфраструктуру
    - перейти в `docker-monolith/infra/terraform`
    - Создать бакет для хранения стейта терраформ командой `terraform apply` 
    - Перейти в `docker-monolith/infra/terraform/prod` На базе example-файла с перемеными создать свой файл, задать количество создаваемых инстансов в переменой `docker_count` создать инстансы командой `terraform apply` 
    - перейти в `docker-monolith/infra/ansible` и выполнить установку ролей: `ansible-galaxy install -r environments/prod/requirements.yml`
    - выполнить развертывание приложения командой 
    `ansible-playbook playbooks/site.yml` , при необходимости подставив название своего контейнера в переменную `docker_container_image`

 - Создать образ с установленным Docker  
    перейти в `docker-monolith/infra` и выполнить `packer build -var-file=packer/variables.json packer/docker.json` предварительно создав файл `docker-monolith/infra/packer/variables.json` с нужными значениями переменных по образцу *.example


### Как проверить работоспособность:

Перейти по ссылке `http://<host_ip>:9292`  , где host_ip это localhost, при локальном запуске контейнера, ip-адрес хоста созданного docker-machine или ip-адрес, любого из созданных терраформом инстансов 

_После проверки удалить ненужные инстансы командой `terraform destroy` из папки `docker-monolith/infra/terraform/prod`_


## ДЗ №15 Docker-образа. Микросервисы.

 - [x] Основное ДЗ
 - [x] Задание со *
 - [x] Задание с ** ?
 
### В процессе сделано:

 - в репозиторий добавлены исходные файлы для развертывания микросервисов
 - созданы `Dockerfile` для запуска тестового приложения в виде набора из 3-х микросервисов `post-py`, `comment`, `ui`
 - для базы данных используется докер с MongoDB (`mongo:latest`), для постоянного хранения данных к которому добавлен volume (`docker volume create reddit_db`)
 - собраны образы для микросервисов, проверена работа приложения после запуска 4-х контейнеров.
 - проверена передача переменных среды при запуске контейнера, для переопределения прописанных в `Dockerfile` значений
 - рассмотрены методы оптимизации размера образов, на прмиере образа `ui` 
      - переход на образ `ubuntu`, размер уменьшается до около 400Мб
      - \* при переходе на  `alpine` образ выходит в размере около 200Мб
      - ** далее образ из `alpine` оптимизирован путем удалениея build-пакетов  до 35.7Мб , можно попробовтаь еще уменьшить размер, использовав multi stage сборку на базе scratch-образа, скопировав все, кроме, например таких системных утилит как apk и т.п, которые не нужны для работы ruby. 
      фрагмент таблицы с размерами образов:
      ```
      REPOSITORY          TAG         SIZE
      spinor72/comment    1.0         739MB
      spinor72/post       1.0         102MB
      spinor72/ui         1.0         746MB  # ruby 
      spinor72/ui         2.0         399MB  # ubuntu
      spinor72/ui         2.1         35.7MB # alpine 
      ```
 - Для проверки докер-файлов использован линтер (некоторые проверки отключены в инлайн комментарии докер-файла)
     ```
     docker run --rm -i hadolint/hadolint < ui/Dockerfile
     docker run --rm -i hadolint/hadolint < post-py/Dockerfile
     docker run --rm -i hadolint/hadolint < comment/Dockerfile
     ```

### Как запустить проект:

 - Перейти в папку `/src`
 - Подготовить контейнеы
     ```
    docker pull mongo:latest
    docker build -t <your-dockerhub-login>/post:1.0 ./post-py
    docker build -t <your-dockerhub-login>/comment:1.0 ./comment
    docker build -t <your-dockerhub-login>/ui:2.1 ./ui
    ```

 - Создать том для базы данных и сеть
    ```
    docker volume create reddit_db
    docker network create reddit
    ```

 - Запустить контейнеры (приведен пример с переопределением сетевых алиасов, как для задания * )
    ```
    docker run -d --network=reddit --network-alias=post_db_new --network-alias=comment_db_new mongo:latest
    docker run -d --network=reddit --network-alias=post_new --env POST_DATABASE_HOST=post_db_new <your-dockerhub-login>/post:1.0
    docker run -d --network=reddit --network-alias=comment_new --env COMMENT_DATABASE_HOST=comment_db_new <your-dockerhub-login>/comment:1.0
    docker run -d --network=reddit -p 9292:9292 --env POST_SERVICE_HOST=post_new --env COMMENT_SERVICE_HOST=comment_new <your-dockerhub-login>/ui:2.1
    ```

### Как проверить работоспособность:

Перейти по ссылке `http://<host_ip>:9292`  , где host_ip это localhost, при локальном запуске контейнеров или ip-адрес хоста созданного docker-machine
Сделать один или несколько постов. Убедится, что при убивании  командой `docker kill $(docker ps -q)` и повторном запуске контейнеров  данные не пропадают.


## ДЗ №16 Docker: сети, docker-compose.

 - [x] Основное ДЗ
 - [x] Задание со *
 
### В процессе сделано:

Работа с сетями в Docker
 - изучены сети типов `none`, `host`, `bridge`. 
 - Для задания со * использованы команды
    -  `ip netns`  и  `ip netns exec <namespace> <command>`  для просмотра неймспейсов и запуска команд в нужном неймспейсе
    -  `brctl show` для отображения veth-интерфейсов, подключенных к bridge-интерфейсом докера 
    -  `iptables -nL -t -v` для просмотра правил iptables, обеспечивабщих работу сетей Docker  
    -  `ps ax | grep docker-proxy` для отображения прокси-процесса, используемого дял направления траффика в контейнер
 - Изучен вопрос подключения контейнера к нескольким бридж-сетям и присвоения сетевых алиасов для сетевого взаимодействия конетйнеров 

Работа с docker-compose
 - создан файл `docker-compose.yml` для запуска тестового приложения из микросервисов
 - файл параметризован  с помощью переменных окружения, значения которых загружаются из `.env` файла, образец заполения см. `/src/.env.example`
 - задано базовое имя проекта, с помощью переменной COMPOSE_PROJECT_NAME (или использовать ключ -p при запуске docker-compose)
 - файл docker-compose.yml доработан для использования нескольких сетей и сетевых алиасов
 - для задания * сделан файл `docker-compose.override.yml` в котором изменяются параметры docker-compose, для примера в репозиторий помещен файл   `/src/docker-compose.override.yml.example`, с помощью которого: 
    - опцией bind подключется папка с исходным кодом для микросервисов
    - изменяются параметры запуска сервера puma


### Как запустить проект:

 - Для использования удленного хоста, запустить его с помощью docker-machine и настроить докер на работу с ним, командой
`eval $(docker-machine env docker-host)`

 - Перейти в папку `/src`
 - Скопировать файл `.env.example` в `.env` и задать нужные значения переменных
 - Запустить командой `docker-compose up -d`

Для переопределения параметров контейнеров:

 - скопировать файл `docker-compose.override.yml.example` в `docker-compose.override.yml` , 
 - перенести на `docker-host` код приложений , например, командой `docker-machine scp -r . docker-host:src` или склонировав репозитоирий.
 - задать переменную `SRC_PATH` в файле `.env` (при локлаьном использовании Docker из папки `/src` можно не задавать) 
 - снова запустить `docker-compose up -d`. 
 - В дальнейшем при обновлениия кода приложения сделать перезапуск контейнеров `docker-compose restart`


### Как проверить работоспособность:

Перейти по ссылке `http://<host_ip>:9292`  , где host_ip это localhost, при локальном запуске контейнеров или ip-адрес хоста созданного docker-machine

Должен открыться интерфейс тестового приложения в котором можно делать посты и комментарии


## ДЗ №17 Устройство Gitlab CI. Построение процесса непрерывной интеграции.

 - [x] Основное ДЗ
 - [x] Задание со *
 
### В процессе сделано:

 - Для работы с Gitlab CE поднят инстанс gitlab-host с помощью  docker-machine
    ```
    docker-machine create --driver google --google-disk-size 100 \
    --google-machine-image https://www.googleapis.com/compute/v1/projects/ubuntu-os-cloud/global/images/family/ubuntu-1604-lts \
    --google-machine-type n1-standard-1 \
    --google-zone europe-west4-b \
    gitlab-host
    ```
 - На созданном хосте, используя docker-compose развернут контейнер с сервисом Gitlab в  версии Omnnibus Gitlab
 - Выполнена первичная настройка gitlab
 - Созданы тестовые группа `homework` и проект `example`
 - В  "microservices"-репозиторий добавлен файл описания CI/CD Pipeline `.gitlab-ci.yml` 
 - Добавлен раннер в виде докер-сервиса и зарегистрирован для использования в CI/CD pipline тестового проекта на Gitlab
 - В приложение reddit добавлены тесты и необходимые библиотеки для тестирования
 - "microservices"-репозиторий синхронизирован в тестовый проект на gitlab
 - проверено что изменение кода в папке приложения reddit привозит к запуску pipeline и оно корректно срабатывает 

Для задания со * 

 - Для автоматического масштабирования раннеров можно использовать возможность autoscaling раннеров https://docs.gitlab.com/runner/configuration/autoscale.html 
 - Можно генерировать инфраструктуру раннеров с помощью terrafrom, образ с "запеченным" раннером и докером делатся пакером, который использует `ansible` для провижининга. Регистрация раннеров происходит при провижининге терраформом в `remote-exec`. Пример приведен в папке /gitlab-runner . Но если предполагается изменение инфрастурктуры то, видимо,нужно еще синхронизировать наличие раннеров с gitlab, например удалять отсутствующие. Для этого можно использовать API Gitlab и соответственно написать скрипт.
 
 - Настроена интеграция Pipeline с тестовым  Slack-чатом 


### Как запустить проект:

 - Установить или использовать готовую утсановку Gitlab пусть это бует адрес  `http://<gitlab-ip>`
 - Создать группу и проект /homework/example
 - Добавить к тееущему "microservices"-репозиторию удаленный репозиторий на gitlab
    `git remote add gitlab http://<gitlab-ip>/homework/example.git `
    `git push gitlab gitlab-ci-1`
 -  создать и зарегистрировать раннер , например, с помощью пакер и терраформ из папки gitlab-runner 
     - Задать свои значения переменных в `/gitlab-runner/packer/variables.json`, для образца использовать example-файл
     - Перейти в папку `/gitlab-runner` и создать образ пакером `packer build -var-file=packer/variables.json packer/gitlab-runner.json`
     - В папке `/gitlab-runner/terraform`  создать файл `terraform.tfvars`со своими значеними переменных (для образца использовать example-файл и кроме параметров GCP, необходимо указать адрес http://<gitlab-ip> и токен для регистрации gitlab  а также количество раннеров в переменной `count`) и запустить создание инфраструктуры раннеров терраформом (`terraform init` , `terraform apply`)
    - в settings/ci_cd проекта должны появитьcя зарегистрированные раннеры
 

### Как проверить работоспособность:

 - Должен автоматически стартовать pipeline при коммите  в репозиторий (после отправки изменений в gitlab). Также можно запустить pipeline вручную
 - В slack-канал https://devops-team-otus.slack.com/messages/C9NT0JMSA должны приходить уведомления от gitlab


## ДЗ №18 Устройство Gitlab CI. Непрерывная поставка.

 - [x] Основное ДЗ
 - [x] Задание со *
 
### В процессе сделано:
 
 - Созданы тестовый проект `example2` и в "microservices"-репозиторий добавлен  `remote` на него 
 - зарегистрирован раннер для использования в этом проекте
 - Добавлено Dev окружение в `.gitlab-ci.yml`
 - Добавлены  два новых этапа: `stage` и `production` , к которым добавлены ограничения  для срабатывания
 - Определены динамические окружения для каждой ветки в репозитории, кроме ветки master
 - Проверена работа pipeline в разных ситуациях 

Для задания со *  

 - Включил registry в omnibus установку Gitlab для хранения образов конетйнеров
 - В шаг build добавил сборку контейнера с приложением reddit и сохранение его в gitlab registry
 - Добавил создание сервера для каждого пуша новой ветки и разворачивания на сервере контейнера с приложением и удаление сервера кнопкой

В этом задании используется отдельный shell-раннер который с помощью docker-machine создает и удаляет инстансы для развертывания приложения. Описание инфраструктуры раннеров находится в папке `/gitlab-runner` 


### Как запустить проект:

 - Установить или использовать готовую утсановку Gitlab пусть это бует адрес  `http://<gitlab-ip>`
 - Создать группу и проект, например `/homework/example2`
 - Добавить к текущему "microservices"-репозиторию удаленный репозиторий на gitlab
    `git remote add gitlab http://<gitlab-ip>/homework/example2.git `
    `git push gitlab2 gitlab-ci-2`
 -  создать и зарегистрировать раннеры с помощью пакер и терраформ из папки gitlab-runner 
     - Задать свои значения переменных в `/gitlab-runner/packer/variables.json`, для образца использовать example-файл
     - Перейти в папку `/gitlab-runner` и создать образ пакером `packer build -var-file=packer/variables.json packer/gitlab-runner-machine.json`
     - В папке `/gitlab-runner/terraform`  создать файл `terraform.tfvars`со своими значеними переменных (для образца использовать example-файл и кроме параметров GCP, необходимо указать адрес http://<gitlab-ip> и токен для регистрации gitlab,  а также количество раннеров в переменной `count` и данные gitlab registry) и запустить создание инфраструктуры раннеров терраформом (`terraform init` , `terraform apply`)
     - в settings/ci_cd проекта должны появитьcя зарегистрированные раннеры
     - Добавить переменные в Secret variables  settings/ci_cd нужные для работы docker-machine и билда контейнеров 
        ```
        GITLAB_REGISTRY: 'gitlab-host:4567'
        GCP_PROJECT: 'project-name'
        GCP_ZONE: 'europe-west4-b'
        ```


### Как проверить работоспособность:

 - Должен автоматически стартовать pipeline при коммите  в репозиторий (после отправки изменений в gitlab2).
 - Для тегированных версией коммитов доступны стадии stage и production
 - Должны автоматически появляться новые серверы, на которых развернут код приложения из запушенной ветки
 - Серверы удаляются кнопкой


## ДЗ №19 Введение в мониторинг. Системы мониторинга.

 - [x] Основное ДЗ
 - [x] Задание со *
 
### В процессе сделано:

 - В GCP создан инстанс и сетевые правила
 - Изменена структура каталогов в репозитории
 - Созданы файлы конфигурации для `docker-compose` и `Docker` для развертывания тестового приложения и его мониторинга на базе `Prometheus`
 - Проверена работа мониторинга 
 - Образы залиты в регистри 
    
     - https://hub.docker.com/r/spinor72/ui/
     - https://hub.docker.com/r/spinor72/post/
     - https://hub.docker.com/r/spinor72/comment/
     - https://hub.docker.com/r/spinor72/prometheus/
     - https://hub.docker.com/r/spinor72/percona-mongodb-exporter/
     - https://hub.docker.com/r/spinor72/google-cloudprober/
    

Для задания со *  
 - Добавлен экспортер для MongoDB на базе проекта `Percona Mongodb exporter` https://github.com/percona/mongodb_exporter 
 - Добавлен blackbox мониторинг сервисов `comment`, `post`, `ui` на базе `Cloudprober` https://github.com/google/cloudp
 - Добавлен `Makefile` для автоматизации создания и заливки образов, а также для запуска и остановки контейнеров и др. задач.


### Как запустить проект:

_Предполагается, что настроен доступ к проекту в GCP и установлена утилита make_

 - Переименовать /Docker/.env.example в /Docker/.env и задать значение переменной `USER_NAME`

При необходимости, создать и настроить инстанс:
 - создать с помощью команды `make machine` новый `docker-host` 
 - Настроить Docker на работу с созданным инстансом `eval $(docker-machine env docker-host)`
 - Создать сетевые правила `make firewall`
 - Узнать внешний адрес хоста (host_ip) по результату команды `docker-machine ip docker-host`

Для запуска тестового прилождения с мониторингом:
 - Создать образы `make build`
 - Залогиниться в `docker hub`
 - Залить образы в регистри `make push`
 - Поднять тестовое приложение и сервре мониторинга командой `make up`

(С помощью make clean можно прочистить систему, до или после поднятия сервисов)


### Как проверить работоспособность:

В браузере:
 - `http://<host_ip>:9292` должен отображаться работающий интерфейс тестового приложения
 - `http://<host_ip>:9090` должен отображаться интерфейс Prometheus
 - `http://<host_ip>:9090/targets` должны быть активны  cloudprober comment mongodb node prometheus ui
 - В Prometheus  отображаются метрики всех экспортеров. 

После проверки, можно всё прочистить:
Остановить контейнерные сервисы и сети
`make down`

Прочистить docker от образов и контейнеров
`make clean`

Остановить хост.
`docker-machie stop docker-host`


## ДЗ №20 Мониторинг приложения и инфраструктуры

 - [x] Основное ДЗ
 - [x] Задание со *
 - [x] Задание с ** частично
 - [ ] Задание с ***

### В процессе сделано:

Мониторинг Docker контейнеров расширен путем добавления визуализации метрик, алертинга , метрик приложения и бизнес-метрик
 - выделен отдельный `docker-compose-monitoring.yml` для сервисов мониторинга
 - добавлен сервис cAdvisor  https://github.com/google/cadvisor для наблюдения  за состоянием Docker контейнеров и хоста
 - добавлен сервис Grafana https://grafana.com/  для визуализации данных из Prometheus
    - Импортирован дашборд DockerMonitoring  https://grafana.com/dashboards/893  для мониторинга докера и докер-контейнеров 
    - Настроен дашборд  UI_Service_Monitoring для мониторинга работы приложения с графиками  
        - rate различных HTTP запросов, поступающих UI сервису
        - rate запросов, которые возвращают код ошибки  
        - 95-й перцентиль для выборки времени обработки запросов 
    - Настроен дашборд Business_Logic_Monitoring с графиками  скорости роста значения счетчиков количества постов и комментариев
 - добавлен сервис алертинга на базе Alertmanager (компонент Prometheus)
    - опции прописываются в `.env`
    - настроена отправка сообщений в слак канал (добавлен webhook для отправки в свой канал)
    - добавлены правила alert rules в prometheus
    - проверена работы алертинга


Задания со *
 - Makefile дополнен для билда и пуша новых контейнеров. Цель для сборки докер-машины дополнена опциями, для работа заданий * и **
 - Настроен сбор метрик с Docker в Prometheus. Для того, чтобы метрики отдавались,  нужно при создании докера-машины добавить опции
    ```
    --engine-opt experimental=true \
    --engine-opt metrics-addr=0.0.0.0:9323 \
    ```
 - Добавлен алерт на 95й перцентиль времени ответа UI
 - настроена  интеграция Alertmanager с e-mail помимо слака. Параметры прописываются в `.env`

Задания со **
 - в сервис grafana добавил провижининг дашбордов и источников данных
 - Добавлен сбор метрик со `Stackdriver` . На базе проекта https://github.com/frodenas/stackdriver_exporter . 
    - Собираемые метрики настраиваются через переменную среды `STACKDRIVER_EXPORTER_MONITORING_METRICS_TYPE_PREFIXES` подходящие значения описаны в документации https://cloud.google.com/monitoring/api/metrics_gcp#gcp-compute

    - Для сбора метрик инстанс должен иметь соответствующие права, это предусмотрено в мейкфайле при создании докер-машины опцией
    ```
	--google-scopes=\
	https://www.googleapis.com/auth/devstorage.read_only,\
	https://www.googleapis.com/auth/monitoring,\
	https://www.googleapis.com/auth/logging.write,\
	https://www.googleapis.com/auth/monitoring.write,\
	https://www.googleapis.com/auth/pubsub,\
	https://www.googleapis.com/auth/service.management.readonly,\
	https://www.googleapis.com/auth/servicecontrol,\
	https://www.googleapis.com/auth/trace.append \
    ```
    Чтбы в домашней папке появились параметры для авторизации в GCP, которые потом будут доступны контейнеру со `stackdreiver-exporter` можно, например, запустить команду `docker-machine ssh docker-host gcloud auth list`
    - Если задать список префмксов  - `compute.googleapis.com/instance/cpu,compute.googleapis.com/instance/disk,compute.googleapis.com/instance/network` ,то будут доступны такие метрики инстанса:
     - Для CPU - stackdriver_gce_instance_compute_googleapis_com_instance_cpu_utilization и т д
     - Для диска - stackdriver_gce_instance_compute_googleapis_com_instance_disk_read_bytes_count и т д
     - Для сети - stackdriver_gce_instance_compute_googleapis_com_instance_network_received_bytes_count и т д

Задание с  *** про Autoheal+AWX
 - Реализовано с использованием набора контейнеров с autoheal, awx и сопутствующих сервисов
 - Файлы размещены в каталоге monitoring/autoheal
 - Конфигурация alertmanager дополнена отправкой в autoheal  события о неработающем сервисе
 - Для запуска сервисов используется docker-compose  в monitoring/autoheal/docker-compose.yml
 - Для заполнения данными AWX используется плейбук monitoring/autoheal/ansible/playbooks/awx-autoheal.yml . Для работы нужен tower-cli .  
 - запуск контейнеров AWX осуществляется запуском плейбука monitoring/autoheal/ansible/playbooks/playbook.yml  (настроено брать из  ветки monitoring-2)
 - не все  опции вынесены в .env файл , пока есть хардкод 
 - модули ансибл tower_* не совсем стабильны. пришлось в одном месте вызыыать tower-cli и хитрить с авторизацией (это из-за того, что не используется https)
 - в AWX импортируется ssh ключ который создает docker-machine (путь берется из переменных среды)

### Как запустить проект:

_Предполагается, что настроен доступ к проекту в GCP и установлена утилита make_

 - Переименовать /Docker/.env.example в /Docker/.env и задать значение переменной `USER_NAME`, `GOOGLE_PROJECT_ID`, свои опции для уведомлений `alertmanager`, пароль для grafana `GF_SECURITY_ADMIN_PASSWORD`

Создать и настроить инстанс с нужными параметрами:
 - создать с помощью команды `make machine` новый `docker-host` 
 - Настроить Docker на работу с созданным инстансом `eval $(docker-machine env docker-host)`
 - Создать сетевые правила `make firewall`
 - Узнать внешний адрес хоста (host_ip) по результату команды `docker-machine ip docker-host`

Для запуска тестового прилождения с мониторингом:
 - Создать образы `make build`
 - Залогиниться в `docker hub`
 - Залить образы в регистри `make push`
 - Поднять тестовое приложение и сервисы мониторинга командой `make up up_mon`

Подключитьтся к логам можно командой `make log` для сервисов приложения или  `make log_mon` для сервисов мониторинга
Для проверки отправки сообения в слак - `make alert`

(С помощью `make clean` можно прочистить систему от лишних  образов и контейнеров, до или после поднятия сервисов. `make clean_all` удаляет volumes)

*** Для запуска автостарта контейнеров при падении 
 - Установить модуль ansible-tower-cli например, `pip install ansible-tower-cli`
 - Поправить значения переменных TOWER_* в .env
 - запустить создание контенйров `make ap_ah`
 - подождать пока AWX полностью запустится (можно контролировать процесс по логу - `docker logs -f reddit_awx_task_1`
 - заполнить AWX данными `make populate_awx` , при этом может произойти ошибка в таске `Create Start node job template for autoheal jobs`  с сообщением `Playbook not found for project.` это означает что AWX еще не успело слить с репозитория список плейбуков. При повторном запуске , ошибка должна исчезнуть.

### Как проверить работоспособность:

В браузере:
 - `http://<host_ip>:9292` должен отображаться работающий интерфейс тестового приложения
 - `http://<host_ip>:9090` должен отображаться интерфейс Prometheus
 - `http://<host_ip>:3000` должен отображаться интерфейс Grafana, логин пользователем admin и пароль, прописанные при создании в переменной `GF_SECURITY_ADMIN_PASSWORD`
 - В интерфейсе grafana должны отображаться и работать 3 уже настроенных провижинингом дашбордов
 - `http://<host_ip>:8080` должен отображаться интерфейс `CAdvisor`
 - `http://<host_ip>:9093` должен отображаться интерфейс `alertmanager`
 - `http://<host_ip>:9255/metrics` должны быть отображаться матрики `stackdriver`
 - В Prometheus  отображаются метрики всех экспортеров.
 - После остановки сервиса приложения или при превышении порогового значение 95го персентиля приходят уведомления в слак и на почту.

 - `http://<host_ip>:8052/` должен отображаться интерфейс AWX 
 - при остановке, например сервиса comment, через некоторое время он снова запустится.
процесс можно посмотреть в логах контейнеров alertmanager,  autoheal и в интерфейсе AWX

После проверки, можно всё прочистить:
Остановить контейнерные сервисы и сети
`make down_mon down`

Прочистить docker от образов и контейнеров
`make clean`

Остановить хост.
`docker-machie stop docker-host`


## ДЗ №21 Логирование и распределенная трассировка

 - [x] Основное ДЗ
 - [x] Задание со *

### В процессе сделано:

 - Обновлен из репозитория код тестовых микросервисов для добавления функционала логирования.
 - Создан compose-файл для системы логирования на базе EFK-стэка (fluentd+elasticsearch+kibana)
 - Добавлен драйвер логирования fluentd для сервисов post и ui в compose-файле

 - Рассмотрена обработка во fluentd структурированных json логов на примере сервиса post
 - Рассмотрен парсинг неструкттурированных логов на примере сервиса ui с использованием регулярных выражений и grok-шаблонов

 - Изучены возможности инструмента Kibana для визуализации собранных в elasticsearch логов 
    - создание индекс-мапинга
    - просмотр и поиск сообщений
    - просмотр детальных данных и поиск по полям

 - Изучены возможности распределенного трейсинга инструментом Zipkin

Дополнительно
 - В Makefile добвлены опции для выполнения этого ДЗ
 - Поправлен код сервиса post (в соответствии с документацией https://github.com/Yelp/py_zipkin _NOTE: older versions of py_zipkin suggested implementing the transport handler as a function with a single argument. That's still supported and should work with the current py_zipkin version, but it's deprecated._)
    - обновлена версия модуля py_zipkin в requirements.txt
    - для решения проблемы падения списка постов при отсутствии коннекта к zipkin добавлен обработчик ошибки коннекта
    - Поправлен код сервиса post для корректной работы zipkin-клиента при запуске post в версии python 3.6 (не собирались внутренние спаны)
 
Задание * 
 - добавил разборку второго формата логов UI через grok-шаблон
 - Задание про проблему медленного открытия поста:
    - В интерфейсе zipkin видим трейсы длительностью более 3 секунд. Открываем, видим, что спан `db_find_single_post` выполняется слишком долго, в коде находим что этот спан соответствуеь вызову функции find_post()  просматриваем (в этом помогает система контроля версий) и находим добавленную задержку sleep(3)



### Как запустить проект:

_Предполагается, что настроен доступ к проекту в GCP и установлена утилита make_

 - Переименовать /Docker/.env.example в /Docker/.env и задать значение переменной `USER_NAME`, `GOOGLE_PROJECT_ID`, поменять версии сервисов:
`POST_VERSION=logging` `UI_VERSION=logging` `COMMENT_VERSION=logging`

Создать и настроить инстанс с нужными параметрами:
 - создать с помощью команды `make machine` новый `docker-host` 
 - Настроить Docker на работу с созданным инстансом `eval $(docker-machine env docker-host)`
 - Создать сетевые правила `make firewall_puma firewall_logging `
 - Узнать внешний адрес хоста (host_ip) по результату команды `docker-machine ip docker-host`

Для запуска тестового прилождения с логингом:
 - Создать образы `make build_src build_fluentd`
 - Поднять тестовое приложение и сервисы мониторинга командой `make up_log up`


(С помощью `make clean` можно прочистить систему от лишних  образов и контейнеров, до или после поднятия сервисов. `make clean_all` удаляет volumes)

### Как проверить работоспособность:

В браузере:
 - `http://<host_ip>:9292` должен отображаться работающий интерфейс тестового приложения
 - `http://<host_ip>:5601` должен отображаться интерфейс Kibana, просле создания индекса, в разделе Discover можно работать с разобранными логами сервисов ui и post
 - `http://<host_ip>:9411` должен отображаться интерфейс Zipkin, при работе с интерфейсом тестового приложения в нем должен отображаться соответствующие трейсы


После проверки, можно всё прочистить:
Остановить контейнерные сервисы и сети
`make down down_log`

Прочистить docker от образов и контейнеров
`make clean`

Остановить хост.
`docker-machie stop docker-host`


## ДЗ №22 Введение в Kubernetes

 - [x] Основное ДЗ
 - [x] Задание со *

### В процессе сделано:

 - Созданы файлы с Deployment манифестами приложений в папке kubernetes/reddit
    - post-deployment.yml
    - ui-deployment.yml
    - comment-deployment.yml
    - mongo-deployment.yml

 - Пройден туториал *Kubernetes The Hard way*, разработанный инженером Google Kelsey Hightower. https://github.com/kelseyhightower/kubernetes-the-hard-way 

 - На основе туториала созданы плейбуки Ansible для установки и удаления  Kubernetes в GCP .

 - в Makefile добавлены опции для запуска данного ДЗ

### Как запустить проект:

Для запуска проекта должен быть наcтроен доступ для работы с `gcloud`  и установлена утилита `make`

 - Переименовать `/Docker/.env.example` в `/Docker/.env` и задать значение переменной `USER_NAME` и версии образов `post`, `ui`, `comment`, `mongo` 
 
 - Переименовать  `/kubernetes/ansible/inventory.yml.example` в `/kubernetes/ansible/inventory.yml` и задать свои значения параметров доступа в GCP и рабочую папку `work_path`, где будут генерироваться сертификаты и другие файлы в процессе работы плейбуков. Установить свои значения ssh ключей и пользователя

 - установить зависимости из файла `kubernetes/ansible/requirements.txt` , например, командой `sudo pip install --upgrade -r kubernetes/ansible/requirements.txt`

 - Установить необходимые утилиты `kubectl` , `cfssl`, `cfssljson`  командой `make k8s_utils` , которая запускает плейбук ansible с запросом sudo-пароля
 
 - запустить установку кластера Kubernetes командой `make k8s_thw_install` , которая запускает соответствующий плейбук
 
 - Развернуть микросервисы тестового приложения командой `make k8s_deploy_reddit` которая заменит параметры контейнеров из переменых среды и запустит деплойменты командой  вида `kubectl apply -f ...`

### Как проверить работоспособность:

Запустить `kubectl get pods` , в результате должны отобразиться в статусе запущен поды `ui`, `post`, `mongo` и `comment`

Для удаления созданных ресурсов, запустить команду `make k8s_clean_thw`  (очистка рабочей папки регулируется инвентори-переменной `clean_work_path`)


## ДЗ №23 Kubernetes. Запуск кластера и приложения. Модель безопасности.

 - [x] Основное ДЗ
 - [x] Задание со *

### В процессе сделано:

 - Изучены возможности Minikube для локальной работы с Kubernetes
 - Изучены возможности утилиты kubectl(контексты, подключения к кластерам, отображение информации о подах, применение манифестов, неймспейсы, перенаправление портов и т.д)
 
 - Для запуска тестового приложения в kubernetes  в папке `kibernetes/reddit` созданы файлы YAML-манифестов необходимых ресурсов
    - `Deployment`-ресурсы описывающие контейнеры, параметры volume, переменные серды, количество подов, селекторы, метки и метаданные для взаимоувязки ресурсов
    - Ресурсы  типа `Service` для связи компонент между собой и с внешним миром (NodePort) используется и для доступа к базе данных mongo
    - `Namespaces` для отделения среды для разработки приложения от всего остального кластера

 - Изучены возможности аддона Dashoard
 
 - Развернут кластер Kubernetes через gcloud console (настроены сетевые правила, включен дашборд и его service account назначена роль cluster-admin)

Для задания *

 - В папке `kibernetes/terraform` Создана конфигурация Terraform для развертывания Kubenetes-кластера в GKE 
    - основные параметры кластера определены в переменных
    - создается сетевое правило для доступа к кластеру из сети
    - применяется контекст для работы с созданным кластером

 - в папке `kibernetes/dashboard` созданы  манифесты для поднятия dashboard в кластере


### Как запустить проект:

 - Для запуска предварительно должны быть установлены kubectl и Minikube (требуется VirtualBox) и настроен доступ к облаку gcloud

 - Для локального теста, запустить `minikube start`
 - Для теста в облаке. 
   - Переименовать файл `kubernetes/terraform/terraform.tfvars.example` в `kubernetes/terraform/terraform.tfvars`, 
   - задать свои значения переменных 
   - запустить создание инфраструктуры терраформом `terraform init`, `terraform plan`, `terraform apply` из папки `kubernetes/terraform`

Для запуска приложения
 - сперва создать неймспейс командой `kubectl apply -f kibernetes/reddit/dev-namespace.yml` 
 - применить манифесты приложения `kubectl apply -f kibernetes/reddit/ -n dev`


Для запуска аддона дашборда 
 - выполнить команду `kubectl apply -f kibernetes/dashboard/`


### Как проверить работоспособность:

 - Подключиться к дашборду командой  `kubectl proxy` и открыть в браузере страничку http://127.0.0.1:8001/api/v1/namespaces/kube-system/services/http:kubernetes-dashboard:/proxy

 - Найти внешний IP-адрес любой ноды из кластера External IP в выводе`kubectl get nodes -o wide`
 - Найти порт публикации сервиса ui `kubectl describe service ui -n dev | grep NodePort`
 - Открыть страничку с найденными адресом и портом и убедиться, что интерфейс тестового приложения работает

После проверки
 - локлаьный клатер можно удалить командой `minikube delete`
 - Инфрамтурктуры созданню терраформа, удалить `terraform destroy`


## ДЗ №24 Kubernetes. Networks ,Storages.

 - [x] Основное ДЗ
 - [x] Задание со *

### В процессе сделано:

 - Изучено сетеове возаимодействие в Kubernetes
   - Плагин kube-dns
   - kube-proxy, kubenet
   - Сервисы 
     - ClusterIP 
     - NodePort 
   - Балансировка нагрузки
     - LoadBalancer
     - Ingress
   - Терминация TLS в ingres, использование Secret ресурсов
     - для задания с * добавлен создаваемый объект Secret в виде Kubernetes-манифеста  
   - NetworkPolicy для декларативного описания потоков трафика
     - обновлен mongo-network-policy.yml так, чтобы post-сервис дошел до базы данных
 - Изучены возможности по настройке хранения данных
   - emptyDir
   - gcePersistentDisk
   - механизм PersistentVolume
   - запрос на выдачу - PersistentVolumeClaim.
   - Динамическое выделение Volume'ов
   - Использование StorageClass
 - описание инфрастурктуры через терраформ дополнено для включения NetworkPolicy в кластере


### Как запустить проект:

 - Для запуска предварительно должны быть установлены kubectl и настроен доступ к облаку gcloud, для развертывания кластера используется terraform

 - Создать кластер терраформом 
   - Переименовать файл `kubernetes/terraform/terraform.tfvars.example` в `kubernetes/terraform/terraform.tfvars`, 
   - задать свои значения переменных `project` и `zone` 
   - запустить создание инфраструктуры терраформом `terraform init`, `terraform plan`, `terraform apply` из папки `kubernetes/terraform`

Для запуска приложения
 - сперва создать неймспейс командой `kubectl apply -f kibernetes/reddit/dev-namespace.yml` 
 - применить манифесты приложения  `kubectl apply -f kibernetes/reddit/ -n dev`


### Как проверить работоспособность:

 - Найти внешний IP-адрес балансировщика  в выводе команды `kubectl get ing -n dev` 
 - Открыть страничку https с найденными адресом (сертификат самоподписан, игнорировтаь предупреждения браузера) и убедиться, что интерфейс тестового приложения работает (поднятие балансировщика может занимать несколько минут)

После проверки
 - Инфраcтурктуру созданную терраформом удалить командой `terraform destroy` из папки `kubernetes/terraform`
 - ненужные диски удалить в консоли gcloud

_Работающее приложение некоторое время будет доступно по адресу https://35.227.239.160/_


## ДЗ №25 CI/CD в Kubernetes.

 - [x] Основное ДЗ
 - [x] Задание со *

### В процессе сделано:

 - Изучены возможности пакетного менеджера Helm
   - Установка и инициализация `helm` и `tiller`
   - Charts 
     - шаблонизация
     - встроенные переменные
     - пользовательские переменные 
     - функции в шаблонах
   - расширение пользовательскими функциями шаблинизатора  (на примере функции `“<service>.fullname”` в файлах `_helpers.tpl` )
   - Управление зависимостями (на примере chart reddit)
     - команда `helm dep update`
     - requirements.yml
     - переопределение переменных для зависимостей в файле `values.yaml`
   - запуск и обновление chart приложения командами `helm install` `helm update`

 - Развернут Gitlab в Kubernetes
   - добавлен пул нод с дополнительными ресурсами
   - импортирован helm chart Gitlab
   - chart модифицирован для запуска в своём кластере
   - gitlab инсталирован в кластер
   - для корректной работы добавлено разрешение имен на хост c ip-адресом Gitlab
   - установка gitlab инициализирована
   - созданы группа `spinor72` и проекты `ui`, `post`, `comment` для кода тестового приложения и  `reddit-deploy` для установки приложения в k8s
   - в проекты закоммичены  и запушены соответсвующие файлы

 - Настроен запуск CI/CD конвейера в Kubernetes
   - в группу проектов добавлены секретные переменные для досупа к докер-репозиторию 
     - CI_REGISTRY_USER - логин в dockerhub
     - CI_REGISTRY_PASSWORD - пароль от Docker Hub
   - в репизитории `ui`, `post`, `comment` добавлены файлы описания пайплайна `.gitlab-ci.yml` для организации стадий:
     - Build: Сборку докер-образа с тегом master
     - Test: Фиктивное тестирование
     - Release: Смену тега с master на тег из файла VERSION и пуш docker-образа с новым тегом
     - Review для запуска (с помощью `helm` и chart из репозитория `reddit-deploy`) отдельного окружения в Kubernetes  по коммиту в feature-бранч.
     - Cleanup для удаления окружения
   - в репозиторий reddit-deploy  добавлен файл описания пайплайна `.gitlab-ci.yml` для организации деплоя на статичные окружения `staging` и `production`

 - файлы `.gitlab-ci.yml`, полученные в ходе работы, перенесены в папку с исходниками для каждой компоненты приложения.
 - Файл `.gitlab-ci.yml` для reddit-deploy скопированы  в `kubernetes/Charts`
 - Измененные версии файлов `ingress.yaml` и `values.yaml` из чарта `ui` скопированы в `kubernetes/Charts`


Задание *

Добавлена функция `trigger_deploy` для запуска деплоя через пайплайн репозитория `reddit-deploy` 

Функция находится  в файлах  `.gitlab-ci.yml` репозиториев  `ui`, `post`, `comment` и вызывается на стадии `release`

Для корректной работы необходимо 
 - в настройках CI/CD проекта `reddit-deploy` создать `Pipeline trigger`,
 - соответствующий токен сохранить в переменной `DEPLOY_TRIGGER_TOKEN` уровня группы или проекта `ui`, `post`, `comment`
 - добавить переменную `DEPLOY_PROJECT_NAME` со значением `reddit-deploy` в группу или проекты `ui`, `post`, `comment`


### Как запустить проект:

 - Для запуска предварительно должны быть установлены kubectl и настроен доступ к облаку gcloud, для развертывания кластера используется terraform

 - Создать кластер терраформом 
   - Переименовать файл `kubernetes/terraform/terraform.tfvars.example` в `kubernetes/terraform/terraform.tfvars`, 
   - задать свои значения переменных `project` и `zone` 
   - запустить создание инфраструктуры терраформом `terraform init`, `terraform plan`, `terraform apply` из папки `kubernetes/terraform`
 - Настроить пакетный менеджер Helm
   - Установить `helm` версии `2.9.1` из репозитория `https://github.com/kubernetes/helm/releases`
   - задеплоить tiller в кластере `kubectl apply -f kubernetes/tiller/tiller.yml`
   - запустить tiller-сервер `helm init --service-account tiller`

Для запуска приложения и gitlab ci в кластере
 - создать неймспейс командой `kubectl apply -f kibernetes/reddit/dev-namespace.yml`
 - применить манифесты приложения  `helm install --name reddit-test --namespace dev  kubernetes/Charts/reddit`
 - установить Gitlab `helm install --name gitlab --namespace dev   kubernetes/Charts/gitlab-omnibus -f kubernetes/Charts/gitlab-omnibus/values.yaml`
 - Настроить локальное рарешение имен для `gitlab-gitlab` `staging` `production` на ip-адрес из вывода команды `kubectl get service -n nginx-ingress nginx`
 - настроить gitlab на страничке http://gitlab-gitlab задав пароль пользователя root и создав группу c набором проектов `ui`, `post`, `comment`, `reddit-deploy`
 - перенести код компонент приложения в соответствующие проекты
 - перенести чарты reddit в проект reddit-deploy, заменить `ingress.yaml` и `values.yaml` в чарте ui на варианты из корня папки `kubernetes/Charts`
 - добавить переменные для работы пайплайна как описано выше


### Как проверить работоспособность:

  - тестовое приложение должно работать на адресе который можно получить командой  `kubectl get ing -n dev`
  - при пуше в репозиторий gitlab должны срабатывать пайплайны, в результате которых в докер регистри будут появляться новые образы, а в кластере запускаться окружения с тестовым приложением. Список окружений можно посмотреть командой `helm ls` В браузере должны открыватьс странички http://staging http://production и странички ревью-окружений если добавить соответствующее разрешение имен.

После проверки
 - Инфраcтурктуру созданную терраформом удалить командой `terraform destroy` из папки `kubernetes/terraform`
 - ненужные диски удалить в консоли gcloud


## ДЗ №26 Kubernetes. Мониторинг и логирование

 - [x] Основное ДЗ
 - [x] Задание со *

### В процессе сделано:

Изучены особенности мониторинга и логирования в k8s
 - развернут Monitoring Pipeline на базе Prometheus 
    - настройка таргетов для сбора метрик с помощью ServiceDiscovery
    - сбор метрик с Cadvisor, kube-state-metrics, node-exporter
    - сбор метрик приложения reddit (post, comment, ui endpoints) c помощью ServiceDiscovery. 
    - использование механизма label
    - настроено отображение метрик с помощью Grafana 
    - в Grafana добавлены системные дашборды k8s
      - Kubernetes cluster monitoring  https://grafana.com/dashboards/315
      - Kubernetes Deployment metrics https://grafana.com/dashboards/741
    - импортированы дашборды для тестового приложения
    - дашборды приложения параметризованы переменной для фильтрации по `namespace`
    - дополнительно настроен провижининг дашбордов 
 - настроена система логирования на базе стека EFK
 - конфигурация terraform дополнена для развертывания логирования в кластере 
 - дополнен  Makefile опциями для развертывания мониторинга и логирования

Для заданий с * 
 - настроен запуск alertmanager в k8s и для него правила для контроля за доступностью api-сервера и хостов k8s
 - создан cahrt для установки стека EFK 


### Как запустить проект:

 - Для запуска предварительно должны быть установлены kubectl и настроен доступ к облаку gcloud, для развертывания кластера используется terraform

 - Создать кластер терраформом 
   - Переименовать файл `kubernetes/terraform/terraform.tfvars.example` в `kubernetes/terraform/terraform.tfvars`, 
   - задать свои значения переменных `project` и `zone`, отключить RBAC `enable_legacy_abac=true` 
   - запустить создание инфраструктуры терраформом `make k8s_terraform`

 - Настроить пакетный менеджер Helm
   - Установить `helm` версии `2.9.1` из репозитория `https://github.com/kubernetes/helm/releases`
   - настройть helm для работы в кластере `make k8s_helm_init`

 - Для настройки уведомлений alertmanager переименовать файл `kubernetes/prometheus/alertmanager_config.yaml.example` в `kubernetes/prometheus/alertmanager_config.yaml` и задать свои значения для  `slack_api_url` и канала (`channel: '#your_chanel'`)

 - добавить nginx ingress командой `make k8s_nginx_ingress`
   - узнать внешний ip адрес ингреса, например командой `kubectl get svc nginx-nginx-ingress-controller` (нужно немного подождать пока адрес будет выделен)
   - настроить на найденный ip-адрес разрешение имен `reddit-test reddit-prometheus reddit-alertmanager reddit-grafana  production reddit-kibana staging`, например, вписав соответсвующую запись в `/etc/hosts` при использовании Linux

 - развернуть мониторинг командой `make k8s_prometheus`
 - развернуть несколько тестовых приложений в неймспесах `default`, `production`, `staging` командой  `make k8s_reddit`
 - создать набор configmaps для провижининга дашбордов в grafana командой `make k8s_grafana_provisioning`
 - запустить развертывание grafana из helm chart командой `make k8s_grafana`
   - пароль для доступа пользователю admin будет отображен в консоли
 - запустить систему логирования на базе стека `EFK` из соответствующего chart командой  `make k8s_efk`


### Как проверить работоспособность:

проверить в браузере работоспособность развернутого тестового приложения и компонент систем мониторинга и логирования:
 - http://reddit-test , http://production , http://staging , должен отобразиться корректно работающий интерфейс тестового приложения
 - http://reddit-prometheus/targets должны отобразиться настроенные таргеты `kubernetes-apiservers`, `kubernetes-nodes`, `kubernetes-service-endpoints`, `post-endpoints`, `prometheus`, `reddit-production`, `ui-endpoints`, `comment-endpoints`  
 - http://reddit-prometheus/alerts отображаются алерты  APIDown и NodeDown 
 - http://reddit-alertmanager/ отображается интерфейс alertmanager
 - на страничке http://reddit-grafana/ ввести имя пользователя `admin` и пароль, полученный ранее в результате выполнения команды make `k8s_grafana`
    - должен отобразиться интерфейс Grafana с настроенным источником данных и 4мя дашбордами
 - http://reddit-kibana в появившемся интерфейсе настроить индекс по шаблону  `fluentd-*` , перейти в раздел `Discover` и убедиться что приходят логи 
  - для проверки алертинга - при остановке nod-ы кластера должно приходить уведомление в slack канал (GKE само переподнимает nod-ы поэтому алерт может не всегда успеть сработать и для остановки выбирать ноду на которой не запущен prometheus,)

После проверки
 - Инфраcтурктуру созданную терраформом удалить командой `make k8s_terraform_destroy`
