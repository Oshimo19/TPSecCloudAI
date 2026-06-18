-- schema.sql
-- Initialisation base PostgreSQL pour l'application

CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE,
    -- Ne JAMAIS stocker un mot de passe en clair.
    -- Hachage côté API via Argon2 avant insertion.
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(255),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
