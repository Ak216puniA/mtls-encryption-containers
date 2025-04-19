import logging
from flask import Flask, request, jsonify
from utils.crypto import encrypt_data, decrypt_data, init_db


app = Flask(__name__)
init_db()


logging.basicConfig(level=logging.INFO)

@app.before_request
def log_request_info():
    logging.info(f"{request.method} {request.path}")

@app.route('/')
def home():
    return jsonify({"message": "Secure Flask Backend with mTLS 🔐"})

@app.route('/health', methods=['GET'])
def health():
    return jsonify({"status": "ok"}), 200

@app.route('/encrypt', methods=['POST'])
def encrypt():
    data = request.json.get("data", "")
    encrypted = encrypt_data(data)
    return jsonify({"encrypted": encrypted})

@app.route('/decrypt', methods=['POST'])
def decrypt():
    encrypted = request.json.get("encrypted", "")
    decrypted = decrypt_data(encrypted)
    return jsonify({"decrypted": decrypted})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, ssl_context=(
        '/certs/server/server.crt',
        '/certs/server/server.key'
    ))
