#!/usr/bin/env bash
# review-pr.sh — reads a git diff on stdin, outputs a JSON findings array on stdout
set -euo pipefail

DIFF=$(cat)

if [ -z "$(echo "$DIFF" | tr -d '[:space:]')" ]; then
    echo "[]"
    exit 0
fi

PROMPT="You are a strict code reviewer agent. Analyze the git diff below on three axes:

1. REVIEW — bugs, regressions, deleted or weakened tests added to make CI pass
2. SECURITY — hardcoded secrets/API tokens/passwords, SQL injection via string concatenation, auth bypass
3. CHANGELOG — a public behavior was changed but no entry was added under ## [Unreleased] in CHANGELOG.md

Severity rules:
- critical: hardcoded API token/secret, SQL injection via string concatenation, deleted test that covered a behavioral requirement
- warning: debug print() or logging statement left in production code
- info: minor style or changelog issue

Output rules (MANDATORY):
- Respond ONLY with a valid JSON array. No text before, no text after, no markdown fences.
- Each finding: {\"file\": \"<path>\", \"line\": <integer>, \"severity\": \"critical|warning|info\", \"category\": \"review|security|changelog\", \"message\": \"<short description>\"}
- If the diff is clean, respond with exactly: []
- Do NOT invent findings. Be precise about file and line number. When in doubt, omit.
- A false positive on a clean PR is a critical failure — precision over recall.

Diff to analyze:
$DIFF"

# Use API directly if key is set, otherwise fall back to claude -p (local dev)
if [ -n "${ANTHROPIC_API_KEY:-}" ]; then
    python3 - <<PYEOF
import json, os, urllib.request, urllib.error, sys

prompt = """$PROMPT"""
api_key = os.environ["ANTHROPIC_API_KEY"]

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
        parsed = json.loads(text)
        print(json.dumps(parsed, ensure_ascii=False))
        sys.exit(0)

print("[]")
PYEOF
else
    claude -p "$PROMPT"
fi
