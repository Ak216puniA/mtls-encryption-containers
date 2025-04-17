#!/bin/bash

set -e

BASE_DIR=$(dirname "$0")/..
CERTS_DIR="${BASE_DIR}/certs"
CA_DIR="${CERTS_DIR}/ca"
SERVER_DIR="${CERTS_DIR}/server"
CLIENT_DIR="${CERTS_DIR}/client"

mkdir -p "$CA_DIR" "$SERVER_DIR" "$CLIENT_DIR"

echo "🔐 Generating Certificate Authority (CA)..."
openssl genrsa -out "$CA_DIR/ca.key" 4096
openssl req -x509 -new -nodes -key "$CA_DIR/ca.key" -sha256 -days 3650 \
    -out "$CA_DIR/ca.crt" -subj "/CN=Secure Containers CA"

echo "📜 Generating Server Key and CSR..."
openssl genrsa -out "$SERVER_DIR/server.key" 2048
openssl req -new -key "$SERVER_DIR/server.key" -out "$SERVER_DIR/server.csr" \
    -subj "/CN=localhost"

echo "✅ Signing Server Certificate with CA..."
openssl x509 -req -in "$SERVER_DIR/server.csr" -CA "$CA_DIR/ca.crt" -CAkey "$CA_DIR/ca.key" \
    -CAcreateserial -out "$SERVER_DIR/server.crt" -days 365 -sha256

echo "📜 Generating Client Key and CSR..."
openssl genrsa -out "$CLIENT_DIR/client.key" 2048
openssl req -new -key "$CLIENT_DIR/client.key" -out "$CLIENT_DIR/client.csr" \
    -subj "/CN=client"

echo "✅ Signing Client Certificate with CA..."
openssl x509 -req -in "$CLIENT_DIR/client.csr" -CA "$CA_DIR/ca.crt" -CAkey "$CA_DIR/ca.key" \
    -CAcreateserial -out "$CLIENT_DIR/client.crt" -days 365 -sha256

echo "🧹 Cleaning up intermediate files..."
rm "$SERVER_DIR/server.csr" "$CLIENT_DIR/client.csr"
rm "$CA_DIR/ca.srl"

echo "✅ Certificates successfully generated in 'certs/' directory!"
