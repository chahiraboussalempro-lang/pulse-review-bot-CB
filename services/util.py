"""Utilitaires de score Pulse."""
from __future__ import annotations


def clamp_score(score: int, ceiling: int = 10) -> int:
    """Borne un score de priorité entre 0 et `ceiling`."""
    return max(0, min(score, ceiling))
