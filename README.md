🚀 Projet Kubernetes – Déploiement de deux microservices statiques


📋 Objectif du test

Déployer deux microservices NGINX sur un cluster Kubernetes local avec :

    un contenu HTML statique différent pour chaque service (hello RISF / hello ITSF)

    une exposition via Ingress + HTTPS (certificats générés localement)

    des bonnes pratiques de prod (pas de root, Kustomize, découpage logique…)


🛠️ Stack utilisée

    Kubernetes (Kind)

    NGINX

    TLS auto-signé (PKI locale)

    kubectl, kustomize, k9s

    Structure GitOps ready (base/overlays)


📁 Arborescence du projet

Alpineo-test/
├── base/
│   ├── configmaps/          # Contenus HTML injectés par ConfigMap
│   ├── deployments/         # Déploiements NGINX non-root
│   ├── ingress/             # Ingress exposé avec TLS
│   ├── secrets/             # Certificats TLS auto-signés
│   ├── services/            # Services ClusterIP
│   └── volumes/             # PV / PVC / StorageClass (pour ITSF)
├── overlays/
│   └── dev/                 # Overlay namespace + réutilisation des ressources sur d'autre environnement
└── tls-ca/                  # PKI locale : ca.crt, *.crt, *.key, *.csr


🔧 Étapes réalisées
🖼️ 1. Microservice hello-risf

    Création d’un Dockerfile basé sur nginx:alpine contenant une page HTML custom.

    Déploiement d’un pod non-root (user nginx) via Deployment.

    Exposition via Service + Ingress avec certificat signé localement.

💽 2. Microservice hello-itsf

    Page HTML montée via volume persistant (PV + PVC local-path).

    Contenu injecté au démarrage avec initContainer.

    Utilise aussi nginx:alpine, déployé sans root.

🔒 3. HTTPS via Ingress + TLS

    Création d’une PKI locale :

        ca.crt / ca.key pour signer les certifs

        hello-risf.local.domain & hello-itsf.local.domain

    Création des Secret Kubernetes contenant les clés et certificats.

    Ingress configuré avec :

    tls:
      - hosts:
          - hello-risf.local.domain
          - hello-itsf.local.domain
        secretName: risf-tls / itsf-tls

📦 4. Kustomize & Namespaces

    Structure découpée en base/ + overlays/dev pour permettre :

        Réutilisabilité

        Déploiement dans un namespace dédié (alpineo)

        Gestion centralisée des environnements

🌍 Test local
🧪 Préparation :

Ajoute dans /etc/hosts :

127.0.0.1 hello-risf.local.domain
127.0.0.1 hello-itsf.local.domain

Lance le port-forward :

kubectl port-forward -n ingress-nginx svc/ingress-nginx-controller 8443:443

🧼 Test via navigateur :

    https://hello-risf.local.domain:8443

    https://hello-itsf.local.domain:8443