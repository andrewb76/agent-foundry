# Agent Foundry

> **Персональная фабрика AI-агентов с GitOps, безопасностью и наблюдаемостью на базе Kubernetes.**

**Agent Foundry** — это учебный и практический стек для развёртывания, оркестрации и безопасной эксплуатации автономных AI-агентов в локальном Kubernetes (Minikube). Проект объединяет шлюз к LLM, среду для CLI-агентов, векторно-графовую память, автоматизацию, управление секретами и наблюдаемость в единую GitOps-управляемую систему.

## 🎯 Цель проекта

- Изучить Kubernetes и GitOps (ArgoCD) на живом, полезном проекте.
- Построить воспроизводимую среду для работы с AI-агентами (`OpenClaw`, `Herdr`, `opencode` и др.).
- Обеспечить безопасное хранение секретов и управление доступом агентов (Infisical).
- Получить полную наблюдаемость за инфраструктурой и поведением LLM (Prometheus, Loki, Grafana, OTel).
- Создать основу для RAG и агентной памяти на SurrealDB.

## 🏗️ Архитектура (логическая)

```text
┌─────────────────────────────────────────────────────────────────────┐
│                         GitOps (ArgoCD)                             │
│  Git-репозиторий → ArgoCD → автоматическая синхронизация с K8s     │
└───────────────────────────────┬─────────────────────────────────────┘
                                │
┌───────────────────────────────▼─────────────────────────────────────┐
│                    Minikube (локальный Kubernetes)                  │
│                                                                     │
│  ┌─────────────────────┐  ┌─────────────────────┐  ┌─────────────┐ │
│  │    ai-agents        │  │    ai-control       │  │ ai-rag      │ │
│  │  Herdr (локально)   │  │  Omniroute (LLM GW) │  │ SurrealDB   │ │
│  │  OpenClaw           │  │  Paperclip          │  │ Ollama      │ │
│  │  opencode           │  │  n8n                │  │ (эмбеддинги)│ │
│  └─────────────────────┘  └─────────────────────┘  └─────────────┘ │
│                                                                     │
│  ┌─────────────────────┐  ┌─────────────────────┐  ┌─────────────┐ │
│  │    security         │  │    network          │  │ observability│ │
│  │  Infisical Operator │  │  Traefik (Ingress)  │  │ Prometheus  │ │
│  │                     │  │  AdGuard Home       │  │ Loki        │ │
│  │                     │  │  Dashy / Homepage   │  │ Grafana     │ │
│  └─────────────────────┘  └─────────────────────┘  └─────────────┘ │
└─────────────────────────────────────────────────────────────────────┘
```

## 📦 Ключевые компоненты

| Компонент | Роль в стеке | Способ развёртывания |
| :--- | :--- | :--- |
| **Minikube** | Локальный одноузловой кластер Kubernetes для обучения и разработки. | `minikube start` |
| **ArgoCD** | GitOps-контроллер: синхронизирует состояние кластера с Git-репозиторием. | Kubernetes-манифесты |
| **Traefik** | Ingress-контроллер и обратный прокси для доступа к веб-интерфейсам сервисов. | Аддон Minikube (`minikube addons enable traefik`) |
| **Infisical** | Управление секретами (API-ключи, токены) с функциями для AI-агентов (`Agent Proxy`). | Helm (Kubernetes Operator) |
| **Omniroute** | Единый OpenAI-совместимый шлюз к десяткам LLM-провайдеров. | Deployment / Helm (в разработке) |
| **OpenClaw** | Автономный AI-агент для выполнения задач в цифровой среде (почта, календарь, мессенджеры). | Helm / скрипт развёртывания |
| **Paperclip** | Платформа оркестрации «компании» AI-агентов (цели, бюджеты, иерархия). | Helm / Kubernetes-плагин |
| **Herdr** | Терминальный workspace-менеджер для долгоживущих сессий CLI-агентов (opencode, pi). | **Локальная установка** (не в кластере) |
| **SurrealDB** | Мультимодельная БД (векторы + граф + документы) для RAG и агентной памяти. | Helm |
| **n8n** | Low-code автоматизация пайплайнов (реакция на алерты, запуск переиндексации RAG). | Helm |
| **Ollama** | Локальный сервер моделей и эмбеддингов (fallback и приватные задачи). | Helm / Deployment |
| **AdGuard Home** | DNS-фильтр для блокировки рекламы и трекеров на уровне кластера. | Helm |
| **Dashy / Homepage** | Единая панель для доступа ко всем веб-интерфейсам стека. | Helm / Deployment |
| **Prometheus + Grafana + Loki** | Сбор метрик, логов и визуализация (включая AI-специфичные метрики через OTel). | Helm (`kube-prometheus-stack`, `loki-stack`) |

## 🛠️ Предварительные требования

На рабочей машине (Linux / macOS / Windows с WSL2) должны быть установлены:

- **Docker** (или Podman) — драйвер для Minikube.
- **Minikube** (v1.39+).
- **kubectl** — CLI для Kubernetes.
- **Helm** (v3+).
- **Git** — для работы с репозиторием.
- **Node.js** (опционально, для локальной установки Omniroute / Herdr).

Проверка:
```bash
minikube version
kubectl version --client
helm version
```

## 🚀 Быстрый старт

### 1. Запуск Minikube и включение Traefik

```bash
minikube start --driver=docker --cpus=4 --memory=8192
minikube addons enable traefik
```

> **Примечание**: Для доступа к LoadBalancer-сервисам может потребоваться `minikube tunnel` в отдельном терминале.

### 2. Установка ArgoCD

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

Дождитесь готовности подов:
```bash
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd
```

Получите начальный пароль:
```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

Проброс порта для доступа к UI:
```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```
Откройте `https://localhost:8080`, логин `admin`, пароль из команды выше.

### 3. Установка Infisical Operator (управление секретами)

```bash
helm repo add infisical-helm-charts 'https://dl.cloudsmith.io/public/infisical/helm-charts/helm/charts/'
helm repo update
helm install infisical-operator infisical-helm-charts/secrets-operator -n infisical --create-namespace
```

После установки оператора вы сможете создавать ресурсы `InfisicalStaticSecret` для синхронизации секретов в стандартные Kubernetes `Secret`. Инструкции по настройке Machine Identity и подключению к Infisical Cloud (или self-hosted инстансу) — в [официальной документации](https://infisical.com/docs).

### 4. Развёртывание приложений через ArgoCD (GitOps)

Создайте Git-репозиторий (например, `agent-foundry-gitops`) со следующей структурой:

```text
agent-foundry-gitops/
├── apps/
│   ├── omniroute/
│   │   ├── deployment.yaml
│   │   └── service.yaml
│   ├── openclaw/
│   │   └── ... (Helm values или манифесты)
│   ├── surrealdb/
│   │   └── values.yaml
│   └── ...
└── argocd/
    └── application.yaml   # Application, указывающий на apps/
```

Пример `Application` для ArgoCD:
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: agent-foundry
  namespace: argocd
spec:
  project: default
  source:
    repoURL: 'https://github.com/<your-username>/agent-foundry-gitops.git'
    targetRevision: HEAD
    path: apps
  destination:
    server: 'https://kubernetes.default.svc'
    namespace: default
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

Примените:
```bash
kubectl apply -f argocd/application.yaml
```

ArgoCD автоматически развернёт всё, что описано в `apps/`. Дальнейшие изменения в Git будут синхронизироваться с кластером.

### 5. Установка Herdr (локально, вне кластера)

Herdr — это ваш «пульт управления» CLI-агентами. Установите его на рабочей машине:

```bash
# Linux / macOS
curl -fsSL https://herdr.dev/install.sh | sh
# или через Homebrew
brew install herdr
```

После установки запустите `herdr` в терминале и подключите к нему ваши CLI-агенты (`opencode`, `pi` и др.). Herdr будет хранить их сессии и позволит переключаться между ними.

### 6. Доступ к веб-интерфейсам (Traefik Ingress / Dashy)

По мере развёртывания сервисов создавайте `IngressRoute` (или стандартные `Ingress`) для доступа к их UI. Пример для Omniroute:

```yaml
apiVersion: traefik.io/v1alpha1
kind: IngressRoute
metadata:
  name: omniroute-ui
  namespace: default
spec:
  entryPoints:
    - web
  routes:
    - match: Host(`omniroute.local`)
      kind: Rule
      services:
        - name: omniroute
          port: 20128
```

Для единой панели можно развернуть **Dashy** или **Homepage** (Helm-чарты доступны) и добавить туда ссылки на все UI. Конфигурацию панели храните в Git — это обеспечит воспроизводимость.

## ✅ Проверка работоспособности

```bash
# Все поды в кластере
kubectl get pods -A

# ArgoCD Applications (должны быть Synced / Healthy)
kubectl get applications -n argocd

# Проверка Traefik
kubectl get pods -n kube-system | grep traefik

# Проверка Infisical Operator
kubectl get pods -n infisical
```

## 🗺️ Дальнейшие шаги (Roadmap)

- [ ] Добавить **Prometheus + Grafana + Loki** (Helm `kube-prometheus-stack` + `loki-stack`).
- [ ] Настроить **OpenTelemetry Collector** с AI-инструментацией для сбора метрик токенов и латентности.
- [ ] Развернуть **SurrealDB** через Helm и подключить как память для RAG.
- [ ] Настроить **Omniroute** как единый шлюз для всех агентов (включая локальный Ollama).
- [ ] Интегрировать **Infisical Agent Proxy** для безопасной выдачи секретов агентам.
- [ ] Добавить **AdGuard Home** и настроить DNS для кластера.
- [ ] Собрать единый дашборд (**Dashy / Homepage**) и подключить к ArgoCD.
- [ ] Настроить **Paperclip** и запустить первого «сотрудника» (`OpenClaw`).

## 📚 Полезные ссылки

- [Minikube](https://minikube.sigs.k8s.io/docs/)
- [ArgoCD](https://argo-cd.readthedocs.io/)
- [Traefik Ingress Controller](https://doc.traefik.io/traefik/)
- [Infisical Docs](https://infisical.com/docs)
- [Omniroute](https://www.omniroute.online/)
- [OpenClaw](https://docs.openclaw.ai/)
- [Paperclip](https://paperclip.ai/)
- [Herdr](https://herdr.dev/)
- [SurrealDB](https://surrealdb.com/docs)
- [n8n](https://docs.n8n.io/)
