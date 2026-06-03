"""Stockage minimal des tâches Pulse (SQLite, requêtes paramétrées)."""
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
