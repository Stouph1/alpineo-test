#!/bin/bash

set -e

TLS_DIR="tls-ca"
SECRETS_DIR="base/secrets"

echo "Génération des certificats TLS pour l'environnement local"

mkdir -p "$TLS_DIR" "$SECRETS_DIR"

echo "📋 Création de la CA..."
openssl genrsa -out "$TLS_DIR/ca.key" 4096
openssl req -new -x509 -key "$TLS_DIR/ca.key" -sha256 -subj "/C=FR/ST=IDF/L=Paris/O=Alpineo/CN=local-ca" -days 365 -out "$TLS_DIR/ca.crt"

generate_cert() {
    local domain=$1
    local name=$2
    
    echo "🔑 Génération du certificat pour $domain..."
    
    openssl genrsa -out "$TLS_DIR/$name.key" 4096
    
    openssl req -new -key "$TLS_DIR/$name.key" -out "$TLS_DIR/$name.csr" -subj "/C=FR/ST=IDF/L=Paris/O=Alpineo/CN=$domain"
    
    openssl x509 -req -in "$TLS_DIR/$name.csr" -CA "$TLS_DIR/ca.crt" -CAkey "$TLS_DIR/ca.key" -CAcreateserial -out "$TLS_DIR/$name.crt" -days 365 -sha256
    
    cat > "$SECRETS_DIR/$name-tls-secret.yaml" << EOF
apiVersion: v1
kind: Secret
metadata:
  name: $name-tls
type: kubernetes.io/tls
data:
  tls.crt: $(base64 -w 0 "$TLS_DIR/$name.crt")
  tls.key: $(base64 -w 0 "$TLS_DIR/$name.key")
EOF
    
    echo "✅ Certificat $name généré et secret Kubernetes créé"
}

generate_cert "hello-risf.local.domain" "risf"
generate_cert "hello-itsf.local.domain" "itsf"

rm -f "$TLS_DIR"/*.csr

echo ""
echo "🎉 Tous les certificats ont été générés avec succès !"
echo ""
echo " Structure créée :"
echo "   $TLS_DIR/          - Certificats et clés"
echo "   $SECRETS_DIR/      - Secrets Kubernetes"
echo "   127.0.0.1 hello-risf.local.domain"
echo "   127.0.0.1 hello-itsf.local.domain"
echo ""
echo " Vous pouvez maintenant déployer avec : kubectl apply -k overlays/dev/"