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
    with urllib.request.urlopen(req, timeout=5) as resp:
        return resp.status
