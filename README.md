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
 - Созданы плейбуки ansible для установки Docker и развертывания контейнера  с тестовым приложением (bспользуется динамическое инвентори из terraform state в бакете)

### Как запустить проект:

 - Создать контейнер

    В папке docker-monolith создать образ  командами вида
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
