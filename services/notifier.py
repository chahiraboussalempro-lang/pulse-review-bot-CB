"""Formatage des notifications Pulse."""
from __future__ import annotations


def format_notification(user: str, task_title: str, score: int) -> str:
    """Rend une ligne de notification lisible, avec un drapeau selon la priorité."""
    if score >= 8:
        flag = "[!]"
    elif score >= 4:
        flag = "[~]"
    else:
        flag = "[ ]"
    return f"{flag} {user} - « {task_title} » (priorité {score})"
