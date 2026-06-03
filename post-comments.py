"""Post GitHub inline PR comments for each finding in findings.json."""
import json
import os
import sys
import urllib.request
import urllib.error

findings_path = sys.argv[1]
findings = json.load(open(findings_path, encoding="utf-8"))

if not findings:
    print("No findings — nothing to post.")
    sys.exit(0)

token = os.environ["GH_TOKEN"]
repo = os.environ["REPO"]
pr_number = os.environ["PR_NUMBER"]
sha = os.environ["SHA"]

SEVERITY_EMOJI = {
    "critical": "🔴 CRITICAL",
    "warning": "🟡 WARNING",
    "info": "🔵 INFO",
}

def post_comment(finding: dict) -> None:
    severity_label = SEVERITY_EMOJI.get(finding["severity"], finding["severity"].upper())
    body = (
        f"**[AI Review] {severity_label}** — `{finding['category']}`\n\n"
        f"{finding['message']}"
    )
    payload = json.dumps({
        "body": body,
        "commit_id": sha,
        "path": finding["file"],
        "line": finding["line"],
        "side": "RIGHT",
    }).encode()

    req = urllib.request.Request(
        f"https://api.github.com/repos/{repo}/pulls/{pr_number}/comments",
        data=payload,
        headers={
            "Authorization": f"Bearer {token}",
            "Accept": "application/vnd.github+json",
            "X-GitHub-Api-Version": "2022-11-28",
            "Content-Type": "application/json",
        },
    )
    try:
        with urllib.request.urlopen(req) as resp:
            print(f"Posted comment on {finding['file']}:{finding['line']} ({finding['severity']})")
    except urllib.error.HTTPError as e:
        # Line may not be in diff — fall back to a regular PR comment
        body_fallback = (
            f"**[AI Review] {severity_label}** — `{finding['category']}`\n\n"
            f"`{finding['file']}` line {finding['line']}: {finding['message']}"
        )
        payload2 = json.dumps({"body": body_fallback}).encode()
        req2 = urllib.request.Request(
            f"https://api.github.com/repos/{repo}/issues/{pr_number}/comments",
            data=payload2,
            headers={
                "Authorization": f"Bearer {token}",
                "Accept": "application/vnd.github+json",
                "X-GitHub-Api-Version": "2022-11-28",
                "Content-Type": "application/json",
            },
        )
        with urllib.request.urlopen(req2) as resp:
            print(f"Posted fallback comment on {finding['file']}:{finding['line']}")

for finding in findings:
    post_comment(finding)

print(f"Done — {len(findings)} comment(s) posted.")
