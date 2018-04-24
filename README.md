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
