# Домашняя работа к лекции №16 (docker-2)
# Docker контейнеры. Docker под капотом


## настроен travis и pre-commit для работы с новым репозиторием

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
```
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
```

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


# Домашняя работа к лекции №18 (docker-4)
# Сети и Docker-Compose

## Сети

`docker network create <параметры> <имя сети>` - создать сеть

Параметры
-d драйвер, например `-d bridge`
--subnet=адрес_сети/маска

Посмотреть список созданных сетей можно командой:
`docker network ls`

Вывод:
NETWORK ID — индификатор сети.
NAME — Имя сети. Можно задать произвольное имя.
DRIVER — Используемый драйвер для созданной сети.
SCOPE — Где используется.

`docker network connect <network> <container>` подключает контейнер <container> к сети <network>.
`docker network disconnect <network> <container>` отключает контейнер <container> от сети <network>.
`docker network rm <network>` - удалить сеть <network>
`.yes|docker network prune` удалить все созданные сети которые не используются

### Запуск контейнеров с указанием параметров сети

docker run `-- network=`имя сети `--network-alias=`сетевое имя контейнера

## docker-compose

Команды
`docker-compose up -d` - запустить (-d в фоновом режиме)
`docker-compose stop` - Остановить контейнеры
`docker-compose down` - Остановить и удалить контейнеры
`docker-compose restart` - Перезапуск
`docker-compose ps` - Список запущенных контейнеров
`docker-compose config` - проверка и вывод конфигурации
`docker-compose up --build` - пересобрать контейнеры
`docker-compose images` - список имиджей

Задать имя проекта можно с помощью ключа `-p` команды `docker-compose up`
Пример `docker-compose -p $PROJECT_NAME up`

docker-compose.yaml в этом файле настраиваются контейнеры, которые потом они будут созданы автоматически с помощью docker-compose.
Файл использует синтаксис YAML и должен содержать такие данные:
```
version: 'версия'
networks:
  сети
volumes:
  хранилища
services:
  контейнеры
```

в файле можно использовать переменные, значения которым можно можно присваивать в файле `.env`

Пример файла `.env`
```
USER=---------
TAG_UI=3.0
TAG_POST=1.0
TAG_COMMENT=1.0
PORT_UI=80
```

Пример файла `docker-compose.yaml`
```
version: '3.3'
services:
  post_db:
    image: mongo:3.2
    volumes:
      - reddit_db:/data/db
    networks:
      back_net:
        aliases:
        - comment_db
        - post_db
  ui:
    build: ./ui
    image: ${USER}/ui:${TAG_UI}
    environment:
      - POST_SERVICE_HOST=post
      - POST_SERVICE_PORT=5000
      - COMMENT_SERVICE_HOST=comment
      - COMMENT_SERVICE_PORT=9292
    ports:
      - ${PORT_UI}:9292/tcp
    networks:
      - front_net
  post:
    build: ./post-py
    image: ${USER}/post:${TAG_POST}
    environment:
      - POST_DATABASE_HOST=post_db
      - POST_DATABASE=posts
    networks:
      - front_net
      - back_net
  comment:
    build: ./comment
    image: ${USER}/comment:${TAG_COMMENT}
    environment:
      - COMMENT_DATABASE_HOST=comment_db
      - COMMENT_DATABASE=comments
      - APP_HOME='/app'
    networks:
      - front_net
      - back_net

volumes:
  reddit_db:

networks:
  front_net:
    driver: bridge
    ipam:
      driver: default
      config:
        - subnet: 10.0.10.0/29
  back_net:
    driver: bridge
    ipam:
      driver: default
      config:
        - subnet: 10.0.10.8/29
```

# Домашняя работа к лекции №20 (gitlab-ci-1).
# Устройство Gitlab CI. Построение процесса непрерывной интеграции

## создан инстанс VM с предустановленным докером и контейнером с Gitlab-CI, установка выполнена в автоматическом режиме (задание со *) - terraform и ansible роли

Просесс continuous integration (CI) в GitLab работает следующим образом:

1. выполняется push изменений в репозиторий проекта;
2. если в корне проекта есть файл .gitlab-ci.yml, то GitLab понимает, что для этого проекта нужно использовать continuous integration;
3. GitLab ищет запущенный runner, подключенный для этого проекта (или общедоступный, shared runner);
4. GitLab передает файл .gitlab-ci.yml раннеру, который обновляет исходники в своем каталоге для билда (--builds-dir) и выполняет команды, описанные в этом файле;
5. после выполнения команд раннер возвращает в GitLab результаты, которые можно посмотреть рядом с соответствующим коммитом, на вкладке pipelines или вкладке jobs

GITLAB runner — отдельная виртуальная машина, в которой каждый пайплайн запускается в новом докер-контейнере и выполняет тесты из специального файла .gitlab-ci.yml при каждом коммите.
За счет него и реализуется автоматическое тестирование кода.
Раннер умеет запускать задачи различными способами: локально, в докер-контейнерах, в различных облаках или через ssh-коннект к какому либо серверу.
Runner-ов может быть много: индивидуальных и общих для нескольких проектов.
Если их много, в конфигурационном файле (в описании job) используется тэги или 'tags', который указывает какой runner нужно использовать.


Pipeline (конвейер) определяется в репозиторий файлом .gitlab-ci.yml и состоит из задач (jobs) которые и выполняются Gitlab Runner'ами

Pipeline — набор задач, организованных в несколько этапов, в котором можно собрать, протестировать, упаковать код, развернуть готовую сборку в облачный сервис, и пр.,
этап (stage) — единица организации пайплайна, содержит в себе задачу или задачи, этапы выполняются последовательно, Job в одном этапе выполняются параллельно
задача (job) — единица работы в пайплайне. Состоит из скрипта (обязательно), условий запуска, настроек публикации/кеширования артефактов и много другого.

### Соответственно, задача при настройке CI/CD сводится к тому, чтобы создать набор задач (файл .gitlab-ci.yml), реализующих все необходимые действия для сборки, тестирования и публикации кода и артефактов.
Пример файла `.gitlab-ci.yml`
Артефакт в виде текстового файла compiled.txt получается еще на первой стадии.
Содержимое тестируется, и если тест проходит, текстовый файл упаковывается в архив, который доступен для скачивания.

```
image: alpine
stages:
    - compile
    - test
    - package

compile:
    stage: compile
    script: cat file1.txt file2.txt > compiled.txt
    artefacts:
       paths:
       - compiled.txt

test:
    stage: test
    script: cat compiled.txt | grep -q "expected string-result"

package:
    stage: package
    script: cat compiled.txt | gzip > package.gz
    artefacts:
       paths:
       - packages.gz

```
Первой строкой указывается образ (в данном примере alpine). Он будет использоваться для создания контейнера.
Затем перечисляются этапы (stage). Заданные для каждого из них блоки кода будут выполняться в приведенном порядке.
Сначала сборка — compile, потом тестирование — test. В последнюю очередь package — подготовка артефакта — пакета или файла с результатом.

Для описания задачи используются следующие директивы:
•stage — определяет стадию, к которой относится задача;
•script — действия, которые будут произведены, когда запустится задача;
•when — вид задачи (manual означает, что задача будет запускаться из пайплайна вручную);
•tags — теги, определяют каким раннером будет запущена задача.

Пример:
```
deploy to production:
  stage: production
  tags: [deploy]
  when: manual
  script:
    - echo "deploy to production!"
```


# Домашняя работа к лекции №22 (monitoring-1).
# Введение в мониторинг. Модели и принципы работы систем мониторинга

Основная задача мониторинга - обеспечение обратной связи, например
 - состояние оборудования
 - работоспособность сервисов
 - показатели бизнеспроцессов (например число заказов или динамика прибыли)
 - процесс разработки и развертывания приложения

## Prometheus

Prometheus мониторит самые разные системы: серверы, базы данных, отдельные виртуальные машины ...
Prometheus внутри это база данных временных рядов. Пополнение базы происходит данными полученными методом
скрейпинга - технологии получения данных путем извлечения их со страниц веб-ресурсов.
Prometheus самостоятельно извлекает метрики через HTTP-вызовы к определенным конечным точкам, указанным в конфигурации.

Вся конфигурация Prometheus, в отличие от многих других систем мониторинга, происходит
через файлы конфигурации и опции командной строки
`prometheus.yml` - простой конфигурационный файл для сбора метрик

Targets (endpoint) - источник для сбора метрик, представляют собой системы или процессы, за которыми следит Prometheus.
Группы источников объединяются в jobs
Для проверки работоспособности в коде приложений должны содержаться healtcheck'и

Пример:
```
- job_name: 'node'
  static_configs:
    - targets:
        - 'node-exporter:9100'
```

### Exporters
В ситуациях, когда невозможно  реализовать отдачу метрик Prometheus
в коде приложения, мы можем использовать экспортер, который будет
транслировать метрики приложения или системы в формате доступном для
чтения Prometheus
Exporter используется для сбора информации не совместимой с Prometheus
Например: Node exporter для сбора информации о работе Docker хоста

Node Exporter — это экспортер Prometheus для сбора данных о состоянии сервера
с подключаемыми коллекторами метрик. Он позволяет измерять различные ресурсы машины,
такие как использование памяти, диска и процессора.

Пример установки node-exporter в докер контейнер:
```
services:

  node-exporter:
    image: prom/node-exporter:v0.15.2
    user: root
    volumes:
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
      - /:/rootfs:ro
    command:
      - '--path.procfs=/host/proc'
      - '--path.sysfs=/host/sys'
      - '--collector.filesystem.ignored-mount-points="^/(sys|proc|dev|host|etc)($$|/)"'
```
# Домашняя работа к лекции №23 (monitoring-2)
# Мониторинг приложения и инфраструктуры

Настроен сбор метрик с контейнеров cAdvisor
Настроена визуализация мерик Grafana
Созданы Dashboard'ы в Grafana
Настроен алертинг в Alertmanager

## cAdvisor
cAdvisor - это инструмент с открытым исходным кодом для мониторинга контейнера.
Он используется для чтения характеристик производительности и использования ресурсов контейнеров.
Запуск cAdvisor для мониторинга контейнеров:

`docker/docker-compose-monitoring.yml`
```
  cadvisor:
    image: google/cadvisor:v0.29.0
    volumes:
      - "/:/rootfs:ro"
      - "/var/run:/var/run:rw"
      - "/sys:/sys:ro"
      - "/var/lib/docker/:/var/lib/docker:ro"
    ports:
      - "8080:8080"
```

`monitoring/prometheus/prometheus.yml`
```
  - job_name: "cadvisor"
    static_configs:
      - targets:
          - "cadvisor:8080"
```

## Grafana
Grafana — это платформа с открытым исходным кодом для визуализации, мониторинга и анализа данных.
Добавленое Grafana для визуализации метрик:

`docker/docker-compose-monitoring.yml`
```
  grafana:
    image: grafana/grafana:5.0.0
    volumes:
      - grafana_data:/var/lib/grafana
    environment:
      - GF_SECURITY_ADMIN_USER=admin
      - GF_SECURITY_ADMIN_PASSWORD=secret
    depends_on:
      - prometheus
    ports:
      - 3000:3000
volumes:
  grafana_data:
```

## Alertmanager
 Alertmanager - это инструмент для обработки оповещений,
который устраняет дубликаты, группирует и отправляет оповещения соответствующему
получателю. Он может обрабатывать оповещения от клиентских приложений, таких как
Prometheus, и поддерживает множество получателей, включая электронную почту и т.д.
Добавить Alertmanager для оправки сообшений при проблемах:

`docker/docker-compose-monitoring.yml`
```
  alertmanager:
    image: ${USER_NAME}/alertmanager:${TAG_PR}
    command:
      - '--config.file=/etc/alertmanager/config.yml'
    ports:
      - 9093:9093
    networks:
      - front_net

```

`monitoring/alertmanager/config.yml`
```
global:
  slack_api_url: 'url_канала'
route:
  receiver: 'slack-notifications'

receivers:
- name: 'slack-notifications'
  slack_configs:
  - channel: '#имя_канала'
```
### Получение url_канала
Зайти по ссылке 'https://testing-d984700.slack.com/apps/A0F7XDUAZ-incoming-webhookshttps://app.slack.com/'
Кнопкой в правом верхнем углу выбрать рабочее пространство
На странице в списке Choose a channel выбрать канал и нажать кнопку Add incoming WebHooks integration
в поле Webhook URL будет сгенерированный url_канала

Alert rules
`monitoring/prometheus/alerts.yml`
```
groups:
  - name: alert.rules
    rules:
      - alert: InstanceDown
        expr: up == 0
        for: 1m
        labels:
          severity: page
        annotations:
          description: "{{ $labels.instance }} of job {{ $labels.job }} has been down for more than 1 minute"
          summary: "Instance {{ $labels.instance }} down"
```

`monitoring/prometheus/prometheus.yml`
```
rule_files:
  - "alerts.yml"
alerting:
  alertmanagers:
  - scheme: http
    static_configs:
    - targets:
      - "alertmanager:9093"
```


# Домашняя работа к лекции №25 (logging-1)
# Применение системы логирования в инфраструктуре на основе Docker

## Разворачивание стека Elasticsearch Fluentd Kibana (EFK) для сбора логов из контейнеров

`Elasticsearch` — поисковый движок с json rest api, использующий Lucene и написанный на Java.
На самом деле Elasticsearch не вполне самостоятельный поиск. Это, скорее, красивая обертка над библиотекой Apache Lucene
Lucene скорее не полноценный сервис, а просто библиотека для построения поисковых систем.
Все, что она может, — только индексировать и искать, а API для ввода данных, для поисковых запросов,
кластеризация и прочее — это все отдается на откуп «обертке» - Elasticsearch.

`Fluentd` — коллектор (сборщик), который берет на себя роль приема всех логов, их последующего парсинга и
бережного укладывания этого всего добра в индексы Elasticsearch.

`Kibana` — визуализатор, т.е. умеет работать с API Elasticsearch, получать и отображать полученные данные.

`Zipkin` — это это распределенная система отслеживания (трассировщик). Он помогает собирать данные синхронизации,
необходимые для устранения проблем с задержкой в архитектуре микросервиса. Анализируя детали, предоставленные
пользовательским интерфейсом Zipkin, становится легче находить задержки или какие-либо конкретные
проблемы служб в архитектуре взаимосвязанных микросервисов.

Пример докер-файла для системы логгирования `docker/docker-compose-logging.yml`
```
  fluentd:
    image: ${USER_NAME}/fluentd:${TAG_LOG}
    ports:
      - "24224:24224"
      - "24224:24224/udp"
    networks:
      - front_net

  elasticsearch:
    image: elasticsearch:7.4.0
    environment:
      - ELASTIC_CLUSTER=false
      - CLUSTER_NODE_MASTER=true
      - CLUSTER_MASTER_NODE_NAME=es01
      - discovery.type=single-node
    expose:
      - 9200
    ports:
      - "9200:9200"
    networks:
      - front_net

  kibana:
    image: kibana:7.4.0
    ports:
      - "5601:5601"
    networks:
      - front_net

  zipkin:
    image: openzipkin/zipkin:2.21.0
    ports:
      - "9411:9411"
    networks:
      - front_net
      - back_net

```

Настройка Fluentd - докер-файл `logging/fluentd/Dokerfile`
```
FROM fluent/fluentd:v0.12
RUN gem install fluent-plugin-elasticsearch --no-rdoc --no-ri --version 1.9.5
RUN gem install fluent-plugin-grok-parser --no-rdoc --no-ri --version 1.0.0
ADD fluent.conf /fluentd/etc
```
и файл конфигурации - `logging/fluentd/fluent.conf`
```
<source>
  @type forward
  port 24224
  bind 0.0.0.0
</source>

<filter service.post>
  @type parser
  format json
  key_name log
</filter>

<filter service.ui>
  @type parser
  key_name log
  format grok
  grok_pattern %{RUBY_LOGGER}
</filter>

<filter service.ui>
  @type parser
  format grok
  grok_pattern service=%{WORD:service} \| event=%{WORD:event} \| request_id=%{GR
  key_name message
  reserve_data true
</filter>

<match *.**>
  @type copy
  <store>
    @type elasticsearch
    host elasticsearch
    port 9200
    logstash_format true
    logstash_prefix fluentd
    logstash_dateformat %Y%m%d
    include_tag_key true
    type_name access_log
    tag_key @log_name
    flush_interval 1s
  </store>
  <store>
    @type stdout
  </store>
</match>
```
Драйвер для логгирования необходимо задать каждому сервису отдельно, прмер для сервиса UI
```
  ui:
    image: ${USER_NAME}/ui:${TAG_UI}
    environment:
      - POST_SERVICE_HOST=post
      - POST_SERVICE_PORT=5000
      - COMMENT_SERVICE_HOST=comment
      - COMMENT_SERVICE_PORT=9292
      - ZIPKIN_ENABLED=${ZIPKIN_ENABLED}
    ports:
      - ${PORT_UI}:9292/tcp
    networks:
      - front_net
    logging:
      driver: "fluentd"
      options:
        fluentd-address: localhost:24224
        tag: service.ui
```
### ЗАМЕЧАНИЕ: система логирования должна запускаться до сервисов с которых будут собтраться логи.

Неструктурированные логи отличаются отсутствием четкой структуры
данных. Также часто бывает, что формат лог-сообщений не подстроен под
систему централизованного логирования, что существенно увеличивает
затраты вычислительных и временных ресурсов на обработку данных и
выделение нужной информации. Для облегчения задачи парсинга можно использовать grok-шаблоны.
По-сути grok'и - это именованные шаблоны регулярных выражений (очень похоже на функции).
Можно использовать готовый regexp, просто сославшись на него как на функцию.
пример в фрагменте файла конфигурации - `logging/fluentd/fluent.conf`
```
<filter service.ui>
@type parser
key_name log
format grok
grok_pattern %{RUBY_LOGGER}
</filter>

<filter service.ui>
@type parser
format grok
grok_pattern service=%{WORD:service} \| event=%{WORD:event} \| request_id=%{GREEDYDATA:request_id} \| message='%
{GREEDYDATA:message}'
key_name message
reserve_data true
</filter>
```
как видно из фрагмента - используется несколько последовательных шаблонов

## Задание со *
С помощью Zipkin была найдена причина задержки в работе сервиса POST - в файле `post_app.py` в функции `db_find_single_post`
строкой `time.sleep(3)` внесена программная задержка.
.
