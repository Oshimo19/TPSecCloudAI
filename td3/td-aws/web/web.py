import os

import requests
from flask import Flask, render_template_string, request

app = Flask(__name__)

APP_API_URL = f"http://{os.environ['INTERNAL_ALB_DNS']}/api/signup"

FORM = """
<!doctype html>
<html lang="fr">
<head>
  <meta charset="utf-8">
  <title>TD3 - Inscription</title>
</head>
<body>
  <h1>Créer un compte</h1>
  <form method="post" action="/signup">
    <label>Nom complet</label><br>
    <input name="full_name" placeholder="Nom complet"><br><br>

    <label>Email</label><br>
    <input name="email" type="email" placeholder="Email" required><br><br>

    <label>Mot de passe</label><br>
    <input name="password" type="password" placeholder="Mot de passe" required><br><br>

    <button type="submit">S'inscrire</button>
  </form>
</body>
</html>
"""


@app.get("/health")
def health():
    return "ok", 200


@app.get("/")
def form():
    return render_template_string(FORM)


@app.post("/signup")
def signup():
    payload = {
        "full_name": request.form.get("full_name", ""),
        "email": request.form.get("email", ""),
        "password": request.form.get("password", ""),
    }

    try:
        response = requests.post(APP_API_URL, json=payload, timeout=5)
    except requests.RequestException as exc:
        return f"<h1>Erreur</h1><p>Impossible de contacter l'API interne : {exc}</p>", 502

    if response.status_code == 201:
        data = response.json()
        return f"<h1>Inscription réussie</h1><p>Utilisateur créé : {data.get('email')}</p><p><a href='/'>Retour</a></p>", 201

    if response.status_code == 409:
        return "<h1>Erreur</h1><p>Email déjà existant.</p><p><a href='/'>Retour</a></p>", 409

    if response.status_code == 400:
        return f"<h1>Erreur</h1><p>Données invalides : {response.text}</p><p><a href='/'>Retour</a></p>", 400

    return f"<h1>Erreur serveur</h1><p>Réponse API : {response.status_code} {response.text}</p>", 500


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=80)
