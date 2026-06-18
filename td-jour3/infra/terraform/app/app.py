# app.py - Code sdu serveur application (API)

"""
API Flask - Tier Applicatif
"""

import os
import re
import hmac
import hashlib
import psycopg2
from argon2 import PasswordHasher
from psycopg2.errors import UniqueViolation # verfier si une email est deja pris 
from argon2.exceptions import VerifyMismatchError, VerificationError, InvalidHashError
from dotenv import load_dotenv
from flask import Flask, request, jsonify

load_dotenv()    

app = Flask(__name__)

# ─── Configuration base de données ───
DB_CONFIG = {
    "host":     os.environ["DB_HOST"],
    "dbname":   os.environ["DB_NAME"],
    "user":     os.environ["DB_USER"],
    "password": os.environ["DB_PASSWORD"],
    "port":     5432,
}

# ─── Poivre (Pepper) ───
#   Secret global stocké HORS base de données (dans .env ou AWS Secrets Manager)
#
PEPPER = os.environ["PEPPER"].encode('utf-8')

# ─── Configuration Argon2id (OWASP Password Storage Cheat Sheet) ───
#   time_cost   = nombre d'itérations           (OWASP : ≥ 2)
#   memory_cost = mémoire utilisée en Kio       (OWASP : ≥ 19 MiB = 19456 Kio)
#   parallelism = nombre de threads parallèles  (OWASP : ≥ 1)
#   hash_len    = longueur du hash en octets    (RFC 9106 : ≥ 32)
#   salt_len    = longueur du sel en octets     (RFC 9106 : ≥ 16)
#
ARGON2 = PasswordHasher(
    time_cost=2,
    memory_cost=19456,  # 19 MiB
    parallelism=1,
    hash_len=32,
    salt_len=16,
    encoding='utf-8',
)

# ─── Validation des entrées ───
EMAIL_REGEX = re.compile(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')

#   Règles ANSSI :
#   - 12 caractères minimum
#   - 1 majuscule, 1 minuscule, 1 chiffre, 1 caractère spécial
#
PASSWORD_RULES = [
    (lambda p: len(p) >= 12,                    "12 caractères minimum"),
    (lambda p: re.search(r'[A-Z]', p),          "1 majuscule minimum"),
    (lambda p: re.search(r'[a-z]', p),          "1 minuscule minimum"),
    (lambda p: re.search(r'\d', p),             "1 chiffre minimum"),
    (lambda p: re.search(r'[^a-zA-Z0-9]', p),   "1 caractère spécial minimum"),
]

def validate_input(email: str, password: str, full_name: str) -> tuple[bool, str]:
    """Valide les champs d'inscription. Retourne (ok, message_erreur)"""
    if not email or not EMAIL_REGEX.match(email):
        return False, "Email manquant ou invalide"
    for rule, message in PASSWORD_RULES:
        if not rule(password):
            return False, f"Mot de passe invalide : {message}"
    if not full_name or len(full_name.strip()) < 2:
        return False, "Nom complet requis"
    return True, ""

# ─── Hachage avec poivre ───

def apply_pepper(password: str) -> str:
    """
    Applique le poivre via HMAC-SHA256 AVANT le hachage Argon2id.

    Pourquoi HMAC et pas simple concaténation ?
    → HMAC est conçu pour combiner un secret et un message de façon sûre.
    → Evite les attaques par extension de longueur (length extension attacks).
    """
    return hmac.new(PEPPER, password.encode('utf-8'), hashlib.sha256).hexdigest()

def hash_password(password: str) -> str:
    """
    Hachage sécurisé OWASP :
    1. Poivre  (HMAC-SHA256, secret hors BDD)
    2. Argon2id (sel aléatoire automatique, résistant GPU et canaux auxiliaires)
    """
    peppered = apply_pepper(password)
    return ARGON2.hash(peppered)

def verify_password(stored_hash: str, password: str) -> bool:
    """
    Vérifie un mot de passe lors de la connexion.
    Retourne True si correct, False sinon.
    """
    peppered = apply_pepper(password)
    return ARGON2.verify(stored_hash, peppered)

# ─── Insertion BDD ───

def insert_user(email: str, password_hash: str, full_name: str) -> dict:
    """
    Insère un utilisateur.
    Retourne {"ok": True, "id": ...} ou {"ok": False, "reason": "duplicate"|"error"}
    """
    conn = None
    try:
        conn = psycopg2.connect(**DB_CONFIG)
        with conn:
            with conn.cursor() as cur:
                cur.execute(
                    """
                    INSERT INTO users (email, password_hash, full_name)
                    VALUES (%s, %s, %s)
                    RETURNING id
                    """,
                    (email, password_hash, full_name)
                )
                user_id = cur.fetchone()[0]
        return {"ok": True, "id": user_id}

    except UniqueViolation:
        # Email deja present → erreur
        return {"ok": False, "reason": "duplicate"}
    except Exception as e:
        return {"ok": False, "reason": "error", "message": str(e)}
    finally:
        if conn is not None:
            conn.close()

# ─── Routes ───

@app.get("/health")
def health():
    """
    Health check pour l'ALB.
    """
    return jsonify({"status": "healthy", "service": "api"}), 200


@app.post("/api/signup")
def signup():
    data      = request.get_json(force=True)
    email     = data.get("email", "").strip().lower()
    password  = data.get("password", "")
    full_name = data.get("full_name", "").strip()

    # 1. Validation ANSSI
    ok, msg = validate_input(email, password, full_name)
    if not ok:
        return jsonify({"error": msg}), 400

    # 2. Hash (Poivre + Argon2id)
    password_hash = hash_password(password)

    # 3. Insertion BDD
    result = insert_user(email, password_hash, full_name)

    if not result["ok"]:
        if result.get("reason") == "duplicate":
            return jsonify({"error": "Email déjà enregistré"}), 409
        # Pour déboguer en dev, tu peux logger result.get("message")
        return jsonify({"error": "Erreur serveur"}), 503

    return jsonify({"status": "created", "id": result["id"]}), 201

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=80)
