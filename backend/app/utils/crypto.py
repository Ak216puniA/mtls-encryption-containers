import sqlite3
from cryptography.fernet import Fernet

key = Fernet.generate_key()
cipher = Fernet(key)
DB_FILE = "app/data.db"

def init_db():
    conn = sqlite3.connect(DB_FILE)
    cursor = conn.cursor()
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS secrets (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            ciphertext TEXT NOT NULL
        )
    ''')
    conn.commit()
    conn.close()

def encrypt_data(data: str) -> str:
    encrypted = cipher.encrypt(data.encode()).decode()
    conn = sqlite3.connect(DB_FILE)
    cursor = conn.cursor()
    cursor.execute("INSERT INTO secrets (ciphertext) VALUES (?)", (encrypted,))
    conn.commit()
    conn.close()
    return encrypted

def decrypt_data(token: str) -> str:
    return cipher.decrypt(token.encode()).decode()
