#!/bin/bash

echo "Déploiement automatique du projet Alpineo"
echo ""

echo "🔐 Étape 1/3 : Génération des certificats TLS..."
./scripts/generate-tls.sh

echo ""
echo "📋 Étape 2/3 : Création du namespace..."
kubectl create namespace alpineo 2>/dev/null || echo "   → Namespace alpineo existe déjà"

echo ""
echo "📦 Étape 3/3 : Déploiement sur Kubernetes..."
kubectl apply -k overlays/dev/

echo ""
echo "✅ Déploiement terminé !"
echo ""
echo "🌐 Pour tester :"
echo "   https://hello-risf.local.domain"
echo "   https://hello-itsf.local.domain"