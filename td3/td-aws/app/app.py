import hashlib
import os
import re
import secrets

import psycopg2
import psycopg2.errors
from flask import Flask, jsonify, request

app = Flask(__name__)

DB_CONFIG = {
    "host": os.environ["DB_HOST"],
    "dbname": os.environ["DB_NAME"],
    "user": os.environ["DB_USER"],
    "password": os.environ["DB_PASSWORD"],
    "port": int(os.environ.get("DB_PORT", "5432")),
}

EMAIL_RE = re.compile(r"^[^@\s]+@[^@\s]+\.[^@\s]+$")


def get_conn():
    return psycopg2.connect(**DB_CONFIG)


def hash_password(password: str) -> str:
    salt = secrets.token_hex(16)
    digest = hashlib.sha256(f"{salt}:{password}".encode("utf-8")).hexdigest()
    return f"sha256${salt}${digest}"


def init_schema():
    ddl = """
    CREATE TABLE IF NOT EXISTS users (
      id SERIAL PRIMARY KEY,
      email VARCHAR(255) NOT NULL UNIQUE,
      password_hash VARCHAR(255) NOT NULL,
      full_name VARCHAR(255),
      created_at TIMESTAMPTZ NOT NULL DEFAULT now()
    );
    """
    with get_conn() as conn:
        with conn.cursor() as cur:
            cur.execute(ddl)


@app.get("/health")
def health():
    return "ok", 200


@app.post("/api/signup")
def signup():
    data = request.get_json(force=True, silent=True) or {}
    email = (data.get("email") or "").strip().lower()
    password = data.get("password") or ""
    full_name = (data.get("full_name") or "").strip()

    if not email or not EMAIL_RE.match(email):
        return jsonify({"error": "email invalide"}), 400

    if not password:
        return jsonify({"error": "mot de passe obligatoire"}), 400

    password_hash = hash_password(password)

    try:
        with get_conn() as conn:
            with conn.cursor() as cur:
                cur.execute(
                    """
                    INSERT INTO users (email, password_hash, full_name)
                    VALUES (%s, %s, %s)
                    RETURNING id, created_at;
                    """,
                    (email, password_hash, full_name),
                )
                user_id, created_at = cur.fetchone()

        return jsonify({"status": "created", "id": user_id, "email": email, "created_at": str(created_at)}), 201

    except psycopg2.errors.UniqueViolation:
        return jsonify({"error": "email deja existant"}), 409
    except Exception as exc:
        app.logger.exception("Erreur API signup")
        return jsonify({"error": "erreur serveur", "detail": str(exc)}), 500


try:
    init_schema()
except Exception as exc:
    print(f"Schema initialization failed: {exc}", flush=True)


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=80)
