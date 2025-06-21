#!/bin/bash

echo "Déploiement automatique du projet Alpineo"
echo ""

echo "🔐 Étape 1/4 : Génération des certificats TLS..."
./scripts/generate-tls.sh

echo ""
echo "📁 Étape 2/4 : Préparation du stockage KIND..."
echo "   → Création du répertoire PV dans KIND..."
if docker exec devops-test-alpineo-control-plane mkdir -p /tmp/kind-pv/itsf 2>/dev/null; then
    docker exec devops-test-alpineo-control-plane chown 101:101 /tmp/kind-pv/itsf
    docker exec devops-test-alpineo-control-plane chmod 755 /tmp/kind-pv/itsf
    echo "   ✅ Répertoire PV préparé avec succès"
else
    echo "   ⚠️  Impossible de préparer le répertoire PV (cluster KIND non trouvé?)"
    echo "   → Le déploiement continuera mais le service ITSF pourrait échouer"
fi

echo ""
echo "📋 Étape 3/4 : Création du namespace..."
kubectl create namespace alpineo 2>/dev/null || echo "   → Namespace alpineo existe déjà"

echo ""
echo "📦 Étape 4/4 : Déploiement sur Kubernetes..."
kubectl apply -k overlays/dev/

echo ""
echo "✅ Déploiement terminé !"
echo ""
echo "🌐 Pour tester :"
echo "   https://hello-risf.local.domain"
echo "   https://hello-itsf.local.domain"