enabled: true

mongodb:
    enabled: true
redis:
    enabled: true
consul:
    enabled: true
    server:
        replicas: 1
    ui:
        enabled: false
console:
  enabled: true
  developer: false
  name: console
  replicas: 1
  image:
      name: spaceone/console
      version: 1.8.4.1
  imagePullPolicy: IfNotPresent

  production_json:
      CONSOLE_API:
        ENDPOINT: https://${console-api-domain}
      DOMAIN_NAME: root
      DOMAIN_NAME_REF: localhost
  ingress:
    enabled: true
    host: '${console-domain}'   # host for ingress (ex. *.console.spaceone.dev)
    annotations:
      kubernetes.io/ingress.class: alb
      alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}, {"HTTPS":443}]'
      alb.ingress.kubernetes.io/actions.ssl-redirect: '{"Type": "redirect", "RedirectConfig": { "Protocol": "HTTPS", "Port": "443", "StatusCode": "HTTP_301"}}'
      alb.ingress.kubernetes.io/inbound-cidrs: 0.0.0.0/0 # replace or leave out
      alb.ingress.kubernetes.io/scheme: "internet-facing" # internet-facing
      alb.ingress.kubernetes.io/target-type: instance # Your console and console-api should be NodePort for this configuration.
      alb.ingress.kubernetes.io/certificate-arn: ${certificate-arn} 
      alb.ingress.kubernetes.io/load-balancer-name: spaceone-prd-core-console
      external-dns.alpha.kubernetes.io/hostname: "${console-domain}"

console-api:
  enabled: true
  developer: false
  name: console-api
  replicas: 1
  image:
      name: spaceone/console-api
      version: 1.8.4.1
  imagePullPolicy: IfNotPresent

  production_json:
      cors:
      - http://*
      - https://*
      redis:
          host: redis
          port: 6379
          db: 15
      logger:
          handlers:
          - type: console
            level: debug
          - type: file
            level: info
            format: json
            path: "/var/log/spaceone/console-api.log"
      escalation:
        enabled: false
        allowedDomainId: domain_id
        apiKey: apikey
  ingress:
    enabled: true
    host: '${console-api-domain}'   # host for ingress (ex. console-api.spaceone.dev)
    annotations:
        kubernetes.io/ingress.class: alb
        alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}, {"HTTPS":443}]'
        alb.ingress.kubernetes.io/actions.ssl-redirect: '{"Type": "redirect", "RedirectConfig": { "Protocol": "HTTPS", "Port": "443", "StatusCode": "HTTP_301"}}'
        alb.ingress.kubernetes.io/inbound-cidrs: 0.0.0.0/0 # replace or leave out
        alb.ingress.kubernetes.io/scheme: "internet-facing" # internet-facing
        alb.ingress.kubernetes.io/target-type: instance # Your console and console-api should be NodePort for this configuration.
        alb.ingress.kubernetes.io/certificate-arn: ${certificate-arn}
        alb.ingress.kubernetes.io/load-balancer-name: spaceone-prd-core-console-api
        external-dns.alpha.kubernetes.io/hostname: ${console-api-domain}

identity:
    enabled: true
    replicas: 1
    image:
      name: spaceone/identity
      version: 1.8.4
    imagePullPolicy: Always

    application_grpc:
      HANDLERS:
          authentication:
          - backend: spaceone.core.handler.authentication_handler.AuthenticationGRPCHandler
            uri: grpc://localhost:50051/v1/Domain/get_public_key
          authorization:
          - backend: spaceone.core.handler.authorization_handler.AuthorizationGRPCHandler
            uri: grpc://localhost:50051/v1/Authorization/verify
          mutation:
          - backend: spaceone.core.handler.mutation_handler.SpaceONEMutationHandler

      ENDPOINTS:
      - service: identity
        name: Identity Service
        endpoint: grpc://identity:50051/v1
      - service: inventory
        name: Inventory Service
        endpoint: grpc://inventory:50051/v1
      - service: plugin
        name: Plugin Manager
        endpoint: grpc://plugin:50051/v1
      - service: repository
        name: Repository Service
        endpoint: grpc://repository:50051/v1
      - service: secret
        name: Secret Manager
        endpoint: grpc://secret:50051/v1
      - service: monitoring
        name: Monitoring Service
        endpoint: grpc://monitoring:50051/v1
      - service: config
        name: Config Service
        endpoint: grpc://config:50051/v1
      - service: power_scheduler
        name: Power Scheduler Service
        endpoint: grpc://power-scheduler:50051/v1
      - service: statistics
        name: Statistics Service
        endpoint: grpc://statistics:50051/v1
      - service: billing
        name: Billing Service
        endpoint: grpc://billing:50051/v1

secret:
    enabled: true
    replicas: 1
    image:
      name: spaceone/secret
      version: 1.8.4
    application_grpc:
        BACKEND: ConsulConnector
        CONNECTORS:
            ConsulConnector:
                host: spaceone-consul-server
                port: 8500
    volumeMounts:
        application_grpc: []
        application_scheduler: []
        application_worker: []

repository:
    enabled: true
    replicas: 1
    image:
      name: spaceone/repository
      version: 1.8.4.1
    application_grpc:
        ROOT_TOKEN_INFO:
            protocol: consul
            config:
                host: spaceone-consul-server
            uri: root/api_key/TOKEN

plugin:
    enabled: true
    replicas: 1
    image:
      name: spaceone/plugin
      version: 1.8.4
 
    scheduler: false
    worker: false
    application_scheduler:
        TOKEN_INFO:
            protocol: consul
            config:
                host: spaceone-consul-server
            uri: root/api_key/TOKEN

config:
    enabled: true
    replicas: 1
    image:
      name: spaceone/config
      version: 1.8.4

inventory:
    enabled: true
    replicas: 1
    replicas_worker: 1
    image:
      name: spaceone/inventory
      version: 1.8.4
    scheduler: true
    worker: true
    application_grpc:
        TOKEN_INFO:
            protocol: consul
            config:
                host: spaceone-consul-server
            uri: root/api_key/TOKEN
        collect_queue: collector_q

    application_scheduler:
        TOKEN_INFO:
            protocol: consul
            config:
                host: spaceone-consul-server
            uri: root/api_key/TOKEN
    application_worker:
        TOKEN_INFO:
            protocol: consul
            config:
                host: spaceone-consul-server
            uri: root/api_key/TOKEN
        HANDLERS:
          authentication: []
          authorization: []
          mutation: []

    volumeMounts:
        application_grpc: []
        application_scheduler: []
        application_worker: []

monitoring:
    enabled: true
    replicas: 1
    image:
      name: spaceone/monitoring
      version: 1.8.4
    application_grpc:
      WEBHOOK_DOMAIN: https://monitoring-webhook.example.com
      TOKEN_INFO:
          protocol: consul
          config:
              host: spaceone-consul-server
          uri: root/api_key/TOKEN
      INSTALLED_DATA_SOURCE_PLUGINS:
        - name: AWS CloudWatch
          plugin_info:
            plugin_id: plugin-41782f6158bb
            provider: aws
        - name: Azure Monitor
          plugin_info:
            plugin_id: plugin-c6c14566298c
            provider: azure
        - name: Google Cloud Monitoring
          plugin_info:
            plugin_id: plugin-57773973639a
            provider: google_cloud

    application_rest:
      TOKEN_INFO:
          protocol: consul
          config:
              host: spaceone-consul-server
          uri: root/api_key/TOKEN

    application_scheduler:
      TOKEN_INFO:
          protocol: consul
          config:
              host: spaceone-consul-server
          uri: root/api_key/TOKEN

    application_worker:
      WEBHOOK_DOMAIN: https://monitoring-webhook.example.com
      TOKEN_INFO:
          protocol: consul
          config:
              host: spaceone-consul-server
          uri: root/api_key/TOKEN

    ingress:
        annotations:
            kubernetes.io/ingress.class: alb
            alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}, {"HTTPS":443}]'
            alb.ingress.kubernetes.io/inbound-cidrs: 0.0.0.0/0 # replace or leave out
            alb.ingress.kubernetes.io/scheme: internet-facing
            alb.ingress.kubernetes.io/target-type: ip 
            alb.ingress.kubernetes.io/certificate-arn: ${certificate-arn} 
            alb.ingress.kubernetes.io/healthcheck-path: "/check"
            alb.ingress.kubernetes.io/load-balancer-attributes: idle_timeout.timeout_seconds=600
            alb.ingress.kubernetes.io/load-balancer-name: spaceone-prd-core-monitoring
            external-dns.alpha.kubernetes.io/hostname: ${monitoring_domain} # monitoring-webhook.domain.com
        servicePort: 80
        path: /*

statistics:
    enabled: true
    replicas: 1
    image:
      name: spaceone/statistics
      version: 1.8.4
 
    scheduler: false
    worker: false
    application_scheduler:
        TOKEN_INFO:
            protocol: consul
            config:
                host: spaceone-consul-server
            uri: root/api_key/TOKEN

billing:
    enabled: true
    replicas: 1
    image:
      name: spaceone/billing
      version: 1.8.4

notification:
    enabled: true
    replicas: 1
    image:
      name: public.ecr.aws/megazone/spaceone/notification
      version: 1.8.4 
    application_grpc:
        INSTALLED_PROTOCOL_PLUGINS:
          - name: Slack
            plugin_info:
              plugin_id: slack-notification-protocol
              options: {}
              schema: slack_webhook
          - name: Telegram
            plugin_info:
              plugin_id: plugin-telegram-noti-protocol
              options: {}
              schema: telegram_auth_token
          - name: Email
            plugin_info:
              plugin_id: plugin-email-noti-protocol
              options: {}
              secret_data:
                smtp_host: email-smtp.us-west-2.amazonaws.com
                smtp_port: "587"
                user: aws_access_key_id
                password: aws_secret_access_key
              schema: email_smtp

power-scheduler:
    enabled: false
    replicas: 1
    image:
      name: spaceone/power-scheduler
      version: 1.8.4
 
    scheduler: true
    worker: true
    application_scheduler:
        TOKEN_INFO:
            protocol: consul
            config:
                host: spaceone-consul-server
            uri: root/api_key/TOKEN

cost-saving:
    enabled: false
    scheduler: true
    worker: true
    replicas: 1
    image:
      name: spaceone/cost-saving
      version: 1.8.4

    application_grpc:
        CONNECTORS:
            ProductConnector:
                token: ___CHANGE_INVENTORY_MARKETPLACE_TOKEN___
                endpoint:
                    v1: grpc://inventory.portal.dev.spaceone.dev:50051


    application_scheduler:
        SCHEDULERS:
            cost_saving_scheduler:
                backend: spaceone.cost_saving.scheduler.cost_saving_scheduler.CostSavingScheduler
                queue: cost_saving_q
                interval: 3600
            CONNECTORS:
                ProductConnector:
                    token: ___CHANGE_INVENTORY_MARKETPLACE_TOKEN___
                    endpoint:
                        v1: grpc://inventory.portal.dev.spaceone.dev:50051

            TOKEN: ___CHANGE_YOUR_ROOT_TOKEN___ 

    application_worker:
        CONNECTORS:
            ProductConnector:
                token: ___CHANGE_INVENTORY_MARKETPLACE_TOKEN___
                endpoint:
                    v1: grpc://inventory.portal.dev.spaceone.dev:50051

    volumeMounts:
        application: []
        application_worker: []
        application_scheduler: []
        application_rest: []

spot-automation:
    enabled: false
    scheduler: true
    worker: true
    rest: true
    replicas: 1
    image:
      name: spaceone/spot-automation
      version: 1.8.4

# Overwrite application config
    application_grpc:
        CONNECTORS:
            ProductConnector:
                endpoint:
                    v1: grpc://inventory.portal.dev.spaceone.dev:50051 
                token: ___CHANGE_INVENTORY_MARKETPLACE_TOKEN___
        INTERRUPT:
            salt: ___CHANGE_SALT___
            endpoint: http://spot-automation-proxy.dev.spaceone.dev
        TOKEN_INFO:
            protocol: consul
            config:
                host: spaceone-consul-server
            uri: root/api_key/TOKEN


    # Overwrite scheduler config
    #application_scheduler: {}
    application_scheduler:
        TOKEN: ___CHANGE_YOUR_ROOT_TOKEN___

    # Overwrite worker config
    #application_worker: {}
    application_worker:
        QUEUES:
            spot_controller_q:
                backend: spaceone.core.queue.redis_queue.RedisQueue
                host: redis
                port: 6379
                channel: spot_controller
        CONNECTORS:
            ProductConnector:
                endpoint:
                    v1: grpc://inventory.portal.dev.spaceone.dev:50051 
                token: ___CHANGE_INVENTORY_MARKETPLACE_TOKEN___
        INTERRUPT:
            salt: ___CHANGE_SALT___
            endpoint: http://spot-automation-proxy.dev.spaceone.dev
        TOKEN_INFO:
            protocol: consul
            config:
                host: spaceone-consul-server
            uri: root/api_key/TOKEN

    ingress:
        annotations:
            kubernetes.io/ingress.class: alb
            alb.ingress.kubernetes.io/scheme: internet-facing
            alb.ingress.kubernetes.io/load-balancer-name: spaceone-prd-core-spot-auto
            external-dns.alpha.kubernetes.io/hostname: spot-automation-proxy.dev.spaceone.dev

marketplace-assets:
    enabled: false

supervisor:
    enabled: true
    image:
      name: spaceone/supervisor
      version: 1.8.4
    application: {}
    application_scheduler:
        NAME: root
        HOSTNAME: root-supervisor.svc.cluster.local
        BACKEND: KubernetesConnector
        CONNECTORS:
            RepositoryConnector:
                endpoint:
                    v1: grpc://repository.spaceone.svc.cluster.local:50051
            PluginConnector:
                endpoint:
                    v1: grpc://plugin.spaceone.svc.cluster.local:50051
            KubernetesConnector:
                namespace: root-supervisor
                start_port: 50051
                end_port: 50052
                headless: true
                replica:
                    inventory.Collector: 1
                    inventory.Collector?aws-ec2: 1
                    inventory.Collector?aws-cloud-services: 1
                    inventory.Collector?aws-power-state: 1
                    monitoring.DataSource: 1

        TOKEN_INFO:
            protocol: consul
            config:
                host: spaceone-consul-server.spaceone.svc.cluster.local
            uri: root/api_key/TOKEN

ingress:
    enabled: false

#######################################
# TYPE 1. global variable (for docdb) 
#######################################
global:
    namespace: spaceone
    supervisor_namespace: root-supervisor
    backend:
        sidecar: []
        volumes: []
    frontend:
        sidecar: []
        volumes: []

    shared_conf:
        HANDLERS:
            authentication:
            - backend: spaceone.core.handler.authentication_handler.AuthenticationGRPCHandler
              uri: grpc://identity:50051/v1/Domain/get_public_key
            authorization:
            - backend: spaceone.core.handler.authorization_handler.AuthorizationGRPCHandler
              uri: grpc://identity:50051/v1/Authorization/verify
            mutation:
            - backend: spaceone.core.handler.mutation_handler.SpaceONEMutationHandler
        CONNECTORS:
            IdentityConnector:
                endpoint:
                    v1: grpc://identity:50051
            SecretConnector:
                endpoint:
                    v1: grpc://secret:50051
            RepositoryConnector:
                endpoint:
                    v1: grpc://repository:50051
            PluginConnector:
                endpoint:
                    v1: grpc://plugin:50051
            ConfigConnector:
                endpoint:
                    v1: grpc://config:50051
            InventoryConnector:
                endpoint:
                    v1: grpc://inventory:50051
            MonitoringConnector:
                endpoint:
                    v1: grpc://monitoring:50051
            StatisticsConnector:
                endpoint:
                    v1: grpc://statistics:50051
            BillingConnector:
                endpoint:
                    v1: grpc://billing:50051
            NotificationConnector:
                endpoint:
                    v1: grpc://notification:50051
            PowerSchedulerConnector:
                endpoint:
                    v1: grpc://power-scheduler:50051
        CACHES:
            default:
                backend: spaceone.core.cache.redis_cache.RedisCache
                host: redis
                port: 6379
                db: 0
                encoding: utf-8
                socket_timeout: 10
                socket_connect_timeout: 10