#!/usr/bin/env bash
# review-pr.sh — reads a git diff on stdin, outputs a JSON findings array on stdout
set -euo pipefail

TMP=$(mktemp)
trap 'rm -f "$TMP"' EXIT
cat > "$TMP"

python3 - "$TMP" <<'PYEOF'
import sys, json, os, urllib.request, urllib.error

diff = open(sys.argv[1], encoding="utf-8", errors="replace").read()

if not diff.strip():
    print("[]")
    sys.exit(0)

api_key = os.environ.get("ANTHROPIC_API_KEY", "")
if not api_key:
    sys.exit("Error: ANTHROPIC_API_KEY is not set")

prompt = (
    "You are a strict code reviewer agent. Analyze the git diff below on three axes:\n\n"
    "1. REVIEW — bugs, regressions, deleted or weakened tests added to make CI pass\n"
    "2. SECURITY — hardcoded secrets/API tokens/passwords, SQL injection via string "
    "concatenation, auth bypass\n"
    "3. CHANGELOG — a public behavior was changed but no entry was added under "
    "## [Unreleased] in CHANGELOG.md\n\n"
    "Severity rules:\n"
    "- critical: hardcoded API token/secret, SQL injection via string concatenation, "
    "deleted test that covered a behavioral requirement\n"
    "- warning: debug print() or logging statement left in production code\n"
    "- info: minor style or changelog issue\n\n"
    "Output rules (MANDATORY):\n"
    "- Respond ONLY with a valid JSON array. No text before, no text after, no markdown fences.\n"
    '- Each finding: {"file": "<path>", "line": <integer>, "severity": "critical|warning|info", '
    '"category": "review|security|changelog", "message": "<short description>"}\n'
    "- If the diff is clean, respond with exactly: []\n"
    "- Do NOT invent findings. Be precise about file and line number. When in doubt, omit.\n"
    "- A false positive on a clean PR is a critical failure — precision over recall.\n\n"
    "Diff to analyze:\n"
    + diff[:50000]
)

payload = json.dumps({
    "model": "claude-haiku-4-5-20251001",
    "max_tokens": 2048,
    "messages": [{"role": "user", "content": prompt}],
}).encode()

req = urllib.request.Request(
    "https://api.anthropic.com/v1/messages",
    data=payload,
    headers={
        "x-api-key": api_key,
        "anthropic-version": "2023-06-01",
        "content-type": "application/json",
    },
)

try:
    with urllib.request.urlopen(req) as resp:
        data = json.loads(resp.read())
except urllib.error.HTTPError as e:
    sys.exit(f"API error {e.code}: {e.read().decode()}")

for block in data.get("content", []):
    if block.get("type") == "text":
        text = block["text"].strip()
        # validate JSON before printing
        parsed = json.loads(text)
        print(json.dumps(parsed, ensure_ascii=False))
        sys.exit(0)

print("[]")
PYEOF
