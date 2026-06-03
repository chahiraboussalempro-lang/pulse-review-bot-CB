"""Calcul de priorité d'une tâche Pulse."""
from __future__ import annotations

WEIGHTS = {"low": 1, "medium": 2, "high": 3, "urgent": 5}


def priority_score(severity: str, age_days: int, blocking: bool) -> int:
    """Score de priorité : plus haut = plus urgent."""
    base = WEIGHTS.get(severity, 1)
    return base + age_days
