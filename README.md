# GitOps Deploymet Guideline.

## 📌 Phase 1: GitLab EE Setup (with NFS Storage)
This phase sets up GitLab Enterprise Edition (EE) as the foundation of the GitOps workflow. GitLab EE will host source code, manage CI/CD pipelines, and build Docker images.
All GitLab data is stored on NFS for durability and easy backup.

### Hardware Requirement

| Phase | Server Role | CPU | RAM | Disk | Notes |
| --- | --- | --- | --- | --- | --- |
| **1** | GitLab EE (Source Control + CI/CD) | 4 cores | 8 GB | 50 GB (OS) + NFS mounts for config/logs/data | Requires Docker + Compose. HTTPS + LDAP supported. Persistent storage via NFS. |
| **2** | Nexus Registry (Artifact Storage) | 2 cores | 4 GB | 50 GB (OS) + expandable NFS for ``/nexus-data`` | Stores Docker images, Helm charts, artifacts. Secure with TLS + RBAC. |
| **3** | ArgoCD + Monitoring (GitOps + Observability) | 4 cores | 8 GB | 50 GB (OS) + NFS for Prometheus/Grafana data | Runs ArgoCD for GitOps deployments. Monitoring stack (Prometheus, Grafana, Alertmanager) scrapes metrics from GitLab, Nexus, and later AWX. |

### 🔧 Prerequisites
#### 1. Install Docker
```
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
```
#### 2. Install Docker Compose and Requirements
- Install docker compose
    ```
    sudo curl -L "https://github.com/docker/compose/releases/download/2.24.5/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    docker-compose --version
    ```
- Install git
    - For Ubuntu/Debien
    ```
    sudo apt update -y
    sudo apt install git -y
    ```
    - For Oracl Linux/Red Hat
    ```
    sudo yum update -y
    sudo yum install git -y
    ```
#### 3. Ensure your server has:
- 4 CPU cores
- 8 GB RAM
- 50 GB disk minimum of persistent storage.

#### 4. Prepare NFS Mounts
- Ensure you have an NFS server available.
- Create directories for GitLab EE:
    ```
    mkdir -p /gitlab/config
    mkdir -p /gitlab/logs
    mkdir -p /gitlab/data
    ```
- Mount NFS shares on your GitLab server:
    ```
    sudo mount -t nfs nfs-server:/export/gitlab/config /gitlab/config
    sudo mount -t nfs nfs-server:/export/gitlab/logs /gitlab/logs
    sudo mount -t nfs nfs-server:/export/gitlab/data /gitlab/data
    ```
    Please change nfs-server to your nfs server ip/name.

- Add entries to `/etc/fstab` for persistence.

#### 5. Clone GitLab Deployment from Github:

- Clone Gitlab deployment
```
git clone https://github.com/toysavi/GitOps.git /gitlab/deployment
chmod 755 -R /gitlab/deployment
cd /gitlab/deployment
```

#### 6. Variable update

Please update LDAP configuration with your Active Directory info

- Gitlab config
    - GITLAB_HOST=gitlab.example.com
    - GITLAB_ROOT_PASSWORD=SuperSecret123

    `Please change FQDN name and Gitlab root password.`
- Update SSL Certificate
    - GITLAB_SSL_CERT_PATH=/gitlab/deployment/ssl/gitlab.crt
    - GITLAB_SSL_KEY_PATH=/gitlab/deployment/ssl/gitlab.key
    
    `Please copy your private key certificate to /gitlab/deployment/ssl and rename to your certificate file name.`
- LDAP config
    - LDAP_HOST=ldap.example.com
    - LDAP_BIND_DN=cn=admin,dc=example,dc=com
    - LDAP_BIND_PASSWORD=SuperSecretLDAP
    - LDAP_BASE=dc=example,dc=com
    
    `Please update to your LDAP Config.`
#### 7. Startup GitLab EE
- Place your SSL certs in /etc/gitlab/ssl/ on the host.
- Start GitLab EE:
    ```
    docker compose up -d /gitlab/deployment/gitlab
    ```
- Access GitLab securely at: https://gitlab.example.com


## 📌 Phase 2: Nexus Registry (Artifact Storage)

This phase deploys Sonatype Nexus Repository Manager 3 as the artifact storage for your GitOps pipeline.
It receives Docker images from GitLab EE and serves them to ArgoCD for deployments.
All data is persisted on NFS, mounted directly to /nexus/data, and secured with HTTPS + LDAP.

### 🔧 Prerequisites
#### 1. Install Docker
```
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
```
#### 2. Install Docker Compose and Requirements
- Install docker compose
    ```
    sudo curl -L "https://github.com/docker/compose/releases/download/2.24.5/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    docker-compose --version
    ```
- Install git
    - For Ubuntu/Debien
    ```
    sudo apt update -y
    sudo apt install git -y
    ```
    - For Oracl Linux/Red Hat
    ```
    sudo yum update -y
    sudo yum install git -y
    ```
- Prepare NFS Mount
    ```
    mkdir -p /nexus/data    
    sudo mount -t nfs nfs-server:/export/nexus/data /nexus/data
    ```
    Add to `/etc/fstab` for persistence.

#### 3. Clone Nexus Deployment from Github
- Clone Nexus deployment
    ```
    git clone https://github.com/toysavi/GitOps.git /nexus/deployment
    chmod 755 -R /nexus/deployment
    cd /nexus/deployment
    ```
#### 4. Variable update
Please update LDAP configuration with your Active Directory info and HTTPS certificate paths.
- Nexus config
    -NEXUS_HOST=nexus.example.com
    - NEXUS_ADMIN_USER=admin
    - NEXUS_ADMIN_PASSWORD=SuperSecret456

    `Please change FQDN name and Nexus admin password.`

- Update SSL Certificate
    - NEXUS_SSL_CERT_PATH=/nexus/deployment/ssl/nexus.crt
    - NEXUS_SSL_KEY_PATH=/nexus/deployment/ssl/nexus.key

    Please copy your private key certificate to `/nexus/deployment/ssl` and rename to your certificate file name.

- LDAP config
    - LDAP_HOST=ldap.example.com
    - LDAP_BIND_DN=cn=admin,dc=example,dc=com
    - LDAP_BIND_PASSWORD=SuperSecretLDAP
    - LDAP_BASE=dc=example,dc=com

    `Please update to your LDAP Config.`

#### 5. Startup Nexus

- Start Nexus Registry:
```
docker compose up -d /nexus/deployment/nexus
```
- Access Nexus securely at: https://nexus.example.com

## 📌 Phase 3: ArgoCD + Monitoring (GitOps + Observability)

This phase deploys ArgoCD for GitOps‑based Kubernetes deployments and a monitoring stack (Prometheus, Grafana, Alertmanager) for observability.
All data is persisted on NFS, and HTTPS is enabled for secure access.

### 