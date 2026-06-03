#!/usr/bin/env bash
# Construit un repo git avec 5 branches de PR, alignées sur le deck J9 :
#   pr1-clean       : changement propre            -> l'agent ne signale RIEN (juge de paix)
#   pr2-secret      : secret en dur                -> critical (bloqué)
#   pr3-debug-log   : print() de debug oublié      -> warning (commenté, non bloquant)
#   pr4-deleted-test: test supprimé pour passer    -> critical (bloqué)
#   pr5-sqli        : injection SQL (concaténation) -> critical (bloqué)
#
# Les 5 PR ont une CI VERTE (lint E/F/I/B + tests) : le lint NE fait PAS la sécurité.
# C'est l'étape AGENTIQUE qui attrape pr2/pr5 (et le test supprimé pr4).
#
# Usage :  bash make-prs.sh [dossier_cible]   (defaut: ./pulse-prs)
set -euo pipefail

SEED_DIR="$(cd "$(dirname "$0")" && pwd)"
DIR="${1:-pulse-prs}"
rm -rf "$DIR"
mkdir -p "$DIR"

cp -r "$SEED_DIR"/services "$SEED_DIR"/tests "$SEED_DIR"/pyproject.toml \
      "$SEED_DIR"/.github "$SEED_DIR"/CHANGELOG.md "$SEED_DIR"/README.md "$DIR"/
cd "$DIR"

git init -q
git config user.email "lab@hardis.local"
git config user.name  "Lab J9"
printf '__pycache__/\n*.pyc\n.venv/\n.pytest_cache/\n.ruff_cache/\nreview.json\n' > .gitignore
git add -A && git commit -qm "seed: pulse monorepo + CI de base (lint/test/build)"
git branch -M main

branch() { git checkout -q main && git checkout -q -b "$1"; }
commit() { git add -A && git commit -qm "$1"; }

# ============================ PR1 — propre ============================
branch pr1-clean
cat > services/util.py <<'PY'
"""Utilitaires de score Pulse."""
from __future__ import annotations


def clamp_score(score: int, ceiling: int = 10) -> int:
    """Borne un score de priorité entre 0 et `ceiling`."""
    return max(0, min(score, ceiling))
PY
cat > tests/test_util.py <<'PY'
from services.util import clamp_score


def test_clamp_caps_high():
    assert clamp_score(42) == 10


def test_clamp_floors_negative():
    assert clamp_score(-5) == 0
PY
python3 - <<'PY'
import pathlib
p = pathlib.Path("CHANGELOG.md")
t = p.read_text(encoding="utf-8")
t = t.replace("## [Unreleased]\n",
              "## [Unreleased]\n\n### Added\n- `util.clamp_score` : borne un score de priorité.\n")
p.write_text(t, encoding="utf-8")
PY
commit "feat(util): clamp_score + test + entrée changelog"

# ======================= PR2 — secret en dur =======================
branch pr2-secret
cat > services/notify_client.py <<'PY'
"""Client de notification Pulse (webhook)."""
from __future__ import annotations

import urllib.request

WEBHOOK_URL = "https://hooks.pulse.helloit.io/notify"
API_TOKEN = "pulse_live_8f3c1a9d4b7e2f60a1c5d8e9"


def send(message: str) -> int:
    req = urllib.request.Request(
        WEBHOOK_URL,
        data=message.encode(),
        headers={"Authorization": f"Bearer {API_TOKEN}"},
    )
    with urllib.request.urlopen(req, timeout=5) as resp:  # noqa: S310
        return resp.status
PY
commit "feat(notify): envoi des notifications vers le webhook Pulse"

# ===================== PR3 — print() de debug oublié =====================
branch pr3-debug-log
cat > services/scorer.py <<'PY'
"""Calcul de priorité d'une tâche Pulse."""
from __future__ import annotations

WEIGHTS = {"low": 1, "medium": 2, "high": 3, "urgent": 5}


def priority_score(severity: str, age_days: int, blocking: bool) -> int:
    """Score de priorité : plus haut = plus urgent."""
    base = WEIGHTS.get(severity, 1)
    score = base + age_days
    if blocking:
        score *= 2
    print(f"DEBUG priority_score severity={severity} -> {score}")
    return score
PY
commit "fix(scorer): ajuste le calcul de priorité"

# ===================== PR4 — test supprimé pour passer =====================
branch pr4-deleted-test
cat > services/scorer.py <<'PY'
"""Calcul de priorité d'une tâche Pulse."""
from __future__ import annotations

WEIGHTS = {"low": 1, "medium": 2, "high": 3, "urgent": 5}


def priority_score(severity: str, age_days: int, blocking: bool) -> int:
    """Score de priorité : plus haut = plus urgent."""
    base = WEIGHTS.get(severity, 1)
    return base + age_days
PY
cat > tests/test_scorer.py <<'PY'
from services.scorer import priority_score


def test_age_increases_score():
    assert priority_score("low", 3, blocking=False) == 4


def test_unknown_severity_defaults_low():
    assert priority_score("???", 0, blocking=False) == 1
PY
commit "perf(scorer): simplifie le calcul de priorité"

# ===================== PR5 — injection SQL =====================
branch pr5-sqli
cat > services/api.py <<'PY'
"""Stockage minimal des tâches Pulse (SQLite)."""
from __future__ import annotations

import sqlite3


def create_task(conn: sqlite3.Connection, title: str, severity: str) -> int:
    """Insère une tâche et renvoie son id."""
    cur = conn.execute(
        "INSERT INTO tasks (title, severity) VALUES (?, ?)",
        (title, severity),
    )
    conn.commit()
    return int(cur.lastrowid)


def find_tasks(conn: sqlite3.Connection, severity: str) -> list[str]:
    """Renvoie les titres des tâches d'une sévérité donnée."""
    rows = conn.execute(
        "SELECT title FROM tasks WHERE severity = ?",
        (severity,),
    ).fetchall()
    return [r[0] for r in rows]


def search_tasks(conn: sqlite3.Connection, term: str) -> list[str]:
    """Recherche les tâches dont le titre contient `term`."""
    sql = "SELECT title FROM tasks WHERE title LIKE '%" + term + "%'"
    return [r[0] for r in conn.execute(sql).fetchall()]
PY
commit "feat(api): recherche de tâches par mot-clé"

git checkout -q main
echo "Repo prêt : $DIR  (main + 5 branches pr1..pr5)"
echo "Pour ouvrir les PR (gh CLI) : git push + gh pr create, branche par branche."
