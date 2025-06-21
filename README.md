# 🚀 Projet Alpineo - Déploiement Kubernetes avec Ingress HTTPS

## 📋 Objectif du projet

Déployer **deux microservices NGINX** sur un cluster Kubernetes local avec :
- ✅ Contenu HTML statique différent pour chaque service
- ✅ Exposition via **Ingress + HTTPS** (certificats auto-signés)
- ✅ **Accès direct** sans port-forward (production-ready)
- ✅ Bonnes pratiques de production (sécurité, organisation)

## 🛠️ Stack technique

| Technologie | Usage |
|-------------|-------|
| **Kubernetes** | Orchestrateur (Kind pour le local) |
| **NGINX** | Serveur web (images Alpine non-root) |
| **Ingress-NGINX** | Load balancer + terminaison TLS |
| **Kustomize** | Gestion des configurations |
| **OpenSSL** | Génération des certificats TLS |

## 🏗️ Architecture du projet

    ```
    📁 Alpineo-test/
    ├── 📂 base/                     # 🎯 Ressources Kubernetes de base
    │   ├── configmaps/              # 📄 Contenu HTML injecté
    │   ├── deployments/             # 🚀 Déploiements NGINX sécurisés
    │   ├── ingress/                 # 🌐 Exposition HTTPS
    │   ├── secrets/                 # 🔒 Certificats TLS
    │   ├── services/                # 🔗 Services ClusterIP
    │   └── volumes/                 # 💾 Stockage persistant
    ├── 📂 overlays/dev/             # 🎨 Configuration environnement
    ├── 📂 scripts/                  # 🔧 Scripts d'automatisation
    ├── 📂 tls-ca/                   # 🔐 PKI locale (certificats)
    ├── 📜 deploy.sh                 # 🚀 Script de déploiement automatique
    ├── 📜 kind-config.yaml          # ⚙️ Configuration cluster KIND
    └── 📜 ingress-service-patch.yaml # 🔧 Configuration ports fixes
    ```

## 🎯 Les deux microservices

### 🟦 **hello-risf** (Service 1)
- **Type** : Page statique via ConfigMap
- **Contenu** : HTML injecté directement dans NGINX
- **URL** : `https://hello-risf.local.domain`
- **Sécurité** : Utilisateur non-root, lecture seule

### 🟩 **hello-itsf** (Service 2)  
- **Type** : Page via volume persistant
- **Contenu** : HTML monté via PV/PVC avec initContainer
- **URL** : `https://hello-itsf.local.domain`
- **Persistance** : Stockage local avec survie aux redémarrages

## 🚀 Déploiement rapide (1 commande)

### Prérequis
    ```bash
    # Installer les outils nécessaires
    # KIND : https://kind.sigs.k8s.io/docs/user/quick-start/
    # kubectl : https://kubernetes.io/docs/tasks/tools/
    ```

### Déploiement automatique
    ```bash
    # 1. Cloner le repo
    git clone https://github.com/Stouph1/alpineo-test.git
    cd Alpineo-test

    # 2. Créer le cluster et déployer (tout automatique !)
    kind create cluster --name devops-test-alpineo --config kind-config.yaml
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.10.1/deploy/static/provider/cloud/deploy.yaml
    kubectl wait --namespace ingress-nginx --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=90s
    kubectl apply -f ingress-service-patch.yaml
    ./deploy.sh

    # 3. Ajouter les domaines locaux
    echo "127.0.0.1 hello-risf.local.domain" | sudo tee -a /etc/hosts
    echo "127.0.0.1 hello-itsf.local.domain" | sudo tee -a /etc/hosts
    ```

### 🎉 Accès aux applications
- **Service RISF** : https://hello-risf.local.domain
- **Service ITSF** : https://hello-itsf.local.domain

**🔥 Plus besoin de port-forward !** Accès direct sur les ports 80/443 !

## 📋 Détail des composants

### 🔧 **deploy.sh** - Script de déploiement
Automatise 4 étapes :
1. **Génération TLS** : Crée la PKI locale + certificats
2. **Préparation stockage** : Configure les répertoires pour volumes persistants
3. **Namespace** : Crée le namespace `alpineo`  
4. **Déploiement** : Applique toutes les ressources via Kustomize

### 🔐 **Gestion TLS/HTTPS**
- **CA locale** : `tls-ca/ca.crt` (autorité de certification)
- **Certificats** : Générés pour chaque domaine
- **Secrets K8s** : Certificats injectés automatiquement
- **Ingress** : Terminaison TLS avec redirection HTTP→HTTPS

### ⚙️ **Configuration KIND (kind-config.yaml)**
    ```yaml
    # Expose les ports Ingress directement sur l'host
    extraPortMappings:
    - containerPort: 30080  # HTTP
    hostPort: 80
    - containerPort: 30443  # HTTPS  
    hostPort: 443
    ```

### 🔧 **Patch Ingress (ingress-service-patch.yaml)**
Force l'utilisation de ports NodePort fixes au lieu de ports aléatoires :
- **Port 30080** pour HTTP (80)
- **Port 30443** pour HTTPS (443)

## 🔍 Commandes utiles

### Vérification du déploiement
    ```bash
    # État des pods
    kubectl get pods -n alpineo

    # Services et ingress
    kubectl get svc,ingress -n alpineo

    # Logs en cas de problème
    kubectl logs -n alpineo deployment/hello-risf
    kubectl logs -n alpineo deployment/hello-itsf
    ```

### Tests de connectivité
    ```bash
    # Test direct avec curl
    curl -k -H "Host: hello-risf.local.domain" https://localhost
    curl -k -H "Host: hello-itsf.local.domain" https://localhost

    # Vérification des certificats
    openssl s_client -connect localhost:443 -servername hello-risf.local.domain
    ```

### Nettoyage
    ```bash
    # Supprimer le cluster
    kind delete cluster --name devops-test-alpineo

    # Nettoyer /etc/hosts (optionnel)
    sudo sed -i '/hello-.*\.local\.domain/d' /etc/hosts
    ```

## 🔧 Dépannage

### Erreur "PersistentVolume is immutable"
    ```bash
    # Nettoyer les anciens volumes
    kubectl delete -k overlays/dev/
    ./deploy.sh
    ```

### Pod ITSF bloqué en "Init:0/1"
    ```bash
    # Vérifier que le répertoire existe dans KIND
    docker exec devops-test-alpineo-control-plane ls -la /tmp/kind-pv/
    # Le script deploy.sh le crée automatiquement
    ```

## 🛡️ Sécurité implémentée

- ✅ **Containers non-root** : Utilisateur `nginx` (UID 101)
- ✅ **Certificats TLS** : Chiffrement bout-en-bout
- ✅ **Redirection HTTPS** : Pas d'accès HTTP non sécurisé
- ✅ **Namespaces** : Isolation des ressources
- ✅ **ReadOnly filesystems** : Protection contre l'écriture
- ✅ **Resource limits** : CPU/Memory contrôlés

## 🎯 Bonnes pratiques appliquées

### 📁 **Structure GitOps**
- **base/** : Ressources communes réutilisables
- **overlays/dev/** : Configuration spécifique à l'environnement
- **Kustomization** : Gestion déclarative des configurations

### 🔄 **Production-ready**
- **Health checks** : Liveness et readiness probes pour auto-healing
- **Resource limits** : CPU/Memory contrôlés pour stabilité
- **Horizontal scaling** : Ready pour HPA
- **Persistent storage** : Volumes survivant aux redémarrages
- **Security contexts** : Containers sécurisés non-root

### 🏥 **Health Checks détaillés**
    ```yaml
    livenessProbe:   # "Es-tu encore vivant ?"
    httpGet:
        path: /
        port: 8080
    initialDelaySeconds: 10  # Attendre le démarrage
    periodSeconds: 10        # Vérifier toutes les 10s
    
    readinessProbe:  # "Es-tu prêt à servir ?"
    httpGet:
        path: /
        port: 8080
    initialDelaySeconds: 5   # Check plus rapide
    periodSeconds: 5         # Réactivité du load balancing
    ```

## ❓ FAQ

### **Q: Pourquoi deux approches différentes (ConfigMap vs Volume) ?**
**R:** Pour démontrer la maîtrise des deux patterns :
- **ConfigMap** : Idéal pour des configurations statiques
- **Volumes** : Nécessaire pour des données persistantes ou volumineuses

### **Q: Pourquoi un script de patch pour l'Ingress ?**
**R:** KIND génère des ports NodePort aléatoires. Le patch force des ports fixes (30080/30443) pour permettre un accès direct sans port-forward.

### **Q: Peut-on utiliser cette config en production ?**
**R:** La structure est production-ready ! Il faut juste :
- Remplacer KIND par un vrai cluster (EKS, GKE, AKS)
- Utiliser des certificats signés par une CA reconnue
- Adapter les domaines et la configuration réseau

### **Q: Comment ajouter un nouvel environnement ?**
**R:** Créer un nouveau overlay :
    ```bash
    mkdir overlays/staging
    # Copier overlays/dev/kustomization.yaml
    # Adapter la configuration (namespace, replicas, etc.)
    ```

### **Q: Pourquoi des resource limits même pour du HTML statique ?**
**R:** Même nginx "simple" peut consommer des ressources en cas de :
- Pic de trafic inattendu
- Memory leak dans l'image
- Attaque DDoS
Les limits protègent le cluster entier !

---

## 🏆 Résultat final

✅ **2 microservices** déployés avec HTTPS  
✅ **Accès direct** sur localhost (sans port-forward)  
✅ **Sécurisé** (TLS + containers non-root + resource limits)  
✅ **Production-ready** (GitOps, health checks, auto-healing)  
✅ **1 commande** pour tout déployer automatiquement  
✅ **Troubleshooting** intégré et documenté

**🎯 Architecture Kubernetes complète et fonctionnelle !**