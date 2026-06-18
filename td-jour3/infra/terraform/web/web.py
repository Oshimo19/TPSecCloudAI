# web.py - Code du serveur web (formulaire)

"""
Web Flask - Tier web
Formulaire Flask + ALB public
"""

import os
import requests
from flask import Flask, request, render_template_string

app = Flask(__name__)

INTERNAL_ALB_DNS = os.environ.get("INTERNAL_ALB_DNS", "localhost")
APP_API_URL      = f"http://{INTERNAL_ALB_DNS}/api/signup"

FORM_PAGE = """
<!doctype html>
<html>
  <head><title>Inscription</title></head>
  <body>
    <h1>Créer un compte</h1>
    <form method="post" action="/signup">
      <input name="full_name" placeholder="Nom complet" required><br><br>
      <input name="email" type="email" placeholder="Email" required><br><br>
      <input name="password" type="password" placeholder="Mot de passe" required><br><br>
      <button type="submit">S'inscrire</button>
    </form>
  </body>
</html>
"""

SUCCESS_PAGE = """
<!doctype html>
<html>
  <head><title>Succès</title></head>
  <body>
    <h1>Compte créé !</h1>
    <p>Email : {{ email }}</p>
    <a href="/">Retour</a>
  </body>
</html>
"""

ERROR_PAGE = """
<!doctype html>
<html>
  <head><title>Erreur</title></head>
  <body>
    <h1>Erreur</h1>
    <p>{{ message }}</p>
    <a href="/">Retour</a>
  </body>
</html>
"""

# ─── Helpers ───

def error(message, code):
    """Affiche la page d'erreur avec un message et un code HTTP."""
    return render_template_string(ERROR_PAGE, message=message), code

# ─── Routes ───

@app.get("/health")
def health():
    return "ok", 200

@app.get("/")
def form():
    return render_template_string(FORM_PAGE)

@app.post("/signup")
def signup():
    full_name = request.form.get("full_name", "").strip()
    email     = request.form.get("email",     "").strip()
    password  = request.form.get("password",  "")

    # Vérification champs obligatoires
    if not all([full_name, email, password]):
        return error("Tous les champs sont requis", 400)

    # Appel API interne
    response = requests.post(
        APP_API_URL,
        json={"full_name": full_name, "email": email, "password": password},
        timeout=5
    )

    # Réponses API → pages HTML
    RESPONSES = {
        201: lambda: (render_template_string(SUCCESS_PAGE, email=email), 201),
        400: lambda: error(response.json().get("error", "Données invalides"), 400),
        409: lambda: error("Cet email est déjà utilisé", 409),
    }

    handler = RESPONSES.get(response.status_code)
    if handler:
        return handler()
    return error("Erreur serveur, réessayez plus tard", 500)

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=80)
