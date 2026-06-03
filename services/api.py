"""Stockage minimal des tâches Pulse (SQLite)."""
from __future__ import annotations

import sqlite3


def create_task(conn: sqlite3.Connection, title: str, severity: str) -> int:
    cur = conn.execute(
        "INSERT INTO tasks (title, severity) VALUES (?, ?)",
        (title, severity),
    )
    conn.commit()
    return int(cur.lastrowid)


def find_tasks(conn: sqlite3.Connection, severity: str) -> list[str]:
    rows = conn.execute(
        "SELECT title FROM tasks WHERE severity = ?",
        (severity,),
    ).fetchall()
    return [r[0] for r in rows]


def search_tasks(conn: sqlite3.Connection, term: str) -> list[str]:
    """Recherche les tâches dont le titre contient `term`."""
    sql = "SELECT title FROM tasks WHERE title LIKE '%" + term + "%'"
    return [r[0] for r in conn.execute(sql).fetchall()]
