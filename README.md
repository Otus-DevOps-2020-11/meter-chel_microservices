# Домашняя работа к лекции №16 (docker-2)
# Docker контейнеры. Docker под капотом


##настроен travis и pre-commit для работы с новым репозиторием

## Установка Docker
```
url -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable"
apt update && apt-cache policy docker-ce
apt-get install -y docker-ce docker-ce-cli containerd.io
```

### Установка Docker-compose
```
curl -L "https://github.com/docker/compose/releases/download/1.26.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
```

### Установка Docker-machine
```
curl -L "https://github.com/docker/machine/releases/download/v0.16.2/docker-machine-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-machine
chmod +x /usr/local/bin/docker-machine
```

## Работа с Docker контейнерами

### Сделать VM
```
yc compute instance create \
  --name docker-host \
  --zone ru-central1-a \
  --network-interface subnet-name=reddit-app-subnet,nat-ip-version=ipv4 \
  --create-boot-disk image-folder-id=standard-images,image-family=ubuntu-1804-lts,size=15 \
  --ssh-key ~/.ssh/id_rsa.pub
```

### Создать на VM докер хост систему - установить Docker Engine
docker-machine create \
  --driver generic \
  --generic-ip-address=АДРЕС \
  --generic-ssh-user yc-user \
  --generic-ssh-key ~/.ssh/ubuntu \
  docker-host

Посмотреть список
'docker-machine ls'

### Переключится на хост docker-host
'eval $(docker-machine env docker-host)'

### Команда собирает образ Docker из файла докера (dockerfile) из текущего каталога (».«) — последний параметр это имя каталога,
в нашем случае точка указывает, что каталог — текущий.
'docker build -t reddit:latest .'

Посмотреть образы
'docker images'

### Запуск контейнера на основе образа
'docker run --name reddit -d --network=host reddit:latest'

Запуск контейнера после остановки (если была)
'docker start reddit'

## DockerHub

Выполнить регистрацию на сервисе

на рабочем хосте выполнть аутентификацию командой 'login' и ввести пароль

### Загрузка образа в DockrHub
```
docker tag reddit:latest LOGIN/otus-reddit:1.0
docker push LOGIN/otus-reddit:1.0
```

### Проверить работоспособность образа - загрузить на локальную машину (например в другой консоли)
'docker run --name reddit -d -p 9292:9292 ge2rg312qe/otus-reddit:1.0'


## Задание со *

 1. Создан плейбук Ansible 'install_docker.yml' для установки докера

 2. Создан шаблон пакера 'docker.json' для создания образа
```
   "provisioners": [
        {
            "type": "ansible",
            "user": "ubuntu",
            "playbook_file": "../ansible/install_docker.yml"
        }
    ]
```

 3. Создан плейбук Ansible 'run-app.yml' для установки для установки приложения

 4. Создан файл создания VM 'main.tf' создающий заданное число VM и запускающий в VM приложение, исползуется динамическая передача адресов в Ansible
```
   provisioner "local-exec" {
     command = "sleep 60"
   }

   provisioner "local-exec" {
     command = "ansible-playbook --inventory ${self.network_interface.0.nat_ip_address}, run_app.yml"
     working_dir = "../ansible"
   }
```

### Получившаяся стрктура каталогов

docker-monolith/
├── db_config
├── docker-1.log
├── Dockerfile
├── infra
│   ├── ansible
│   │   ├── ansible.cfg
│   │   ├── install_docker.yml
│   │   └── run_app.yml
│   ├── packer
│   │   ├── docker.json
│   │   └── variables.json
│   └── terraform
│       ├── main.tf
│       ├── outputs.tf
│       ├── terraform.tfstate
│       ├── terraform.tfstate.backup
│       ├── terraform.tfvars
│       ├── terraform.tfvars.example
│       └── variables.tf
├── mongod.conf
└── start.sh


# Домашняя работа к лекции №17 (docker-3)
# Docker образы. Микросервисы

## Создать три Dockerfile для новой структуры приложения

 - для сервиса постов
 - для сервиса коментов
 - для веб-интерфейса

## Подключаемся к ранее созданному Docker host’у
`eval $(docker-machine env docker-host)`

## Сборка
```
docker build -t xxxxxxxx/post:1.0 ./post-py
docker build -t xxxxxxxx/comment:1.0 ./comment
docker build -t xxxxxxxx/ui:1.0 ./ui
```

## Создать сеть
`docker network create reddit`
## и запустить контейнеры
```
docker run -d --network=reddit --network-alias=post_db --network-alias=comment_db1 mongo:latest
docker run -d --network=reddit --network-alias=post xxxxxxxx/post:1.0
docker run -d --network=reddit --network-alias=comment xxxxxxxx/comment:1.0
docker run -d --network=reddit -p 9292:9292 xxxxxxxx/ui:1.0
```

### для удобства перезапуска контейнеров создал скрипт run.sh

## VOLUME
Создать `docker volume create reddit_db`
Использование `-v reddit_db:/data/db`
Пример:
`docker run -d --network=reddit --network-alias=post_db --network-alias=comment_db -v reddit_db:/data/db mongo:latest`
Подключение VOLUME дало возможность сохранять данные при отключении или перезапуске контейнера

## Задание со *

### Остановить и запустить приложения с другими алиасами

docker kill $(docker ps -q)
В командах запуска редактируются ключи `--network-alias= ` переменные (ENV) нужно отредактировать в докерфайлах,
но можно передать через `--env` при запуске, например:
`docker run -d --network=reddit -p 9292:9292 --env POST_SERVICE_HOST=значение --env COMMENT_SERVICE_HOST=значение xxxxxxxx/ui:3.0`


### сборка образа на Alpine:
```
FROM alpine:latest

RUN apk update \
    && apk add --no-cache ruby-full ruby-dev build-base \
    && gem install bundler:1.17.2
```
потребовалась именно версия bundler:1.17.2, без указания версии сборка прерывалась, видимо особенность образа

Удалось уменьшить размер имиджа ui
```
REPOSITORY             TAG            IMAGE ID       CREATED             SIZE
xxxxxxxx/ui            3.0            9544f8ce6eba   About an hour ago   266MB
xxxxxxxx/ui            2.0            32b07928ee0d   5 hours ago         458MB
xxxxxxxx/comment       1.0            911d978e3150   5 hours ago         768MB
xxxxxxxx/post          1.0            2311934c666d   5 hours ago         119MB
xxxxxxxx/ui            1.0            25aa8cf1157e   7 hours ago         771MB
xxxxxxxx/otus-reddit   1.0            9376b953d323   4 days ago          702MB
```
...
