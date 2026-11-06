import json
import os
import subprocess
import sys


def main():
    try:
        payload = json.load(sys.stdin)
    except Exception:
        payload = {}
    if payload.get("stop_hook_active"):
        return 0
    root = os.environ.get("CLAUDE_PROJECT_DIR") or os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    try:
        status = subprocess.run(["git", "-C", root, "status", "--porcelain", "--untracked-files=all"], capture_output=True, text=True, timeout=10).stdout
    except Exception:
        return 0
    changed = []
    for line in status.splitlines():
        path = line[3:].split(" -> ")[-1].strip().strip('"')
        if path.startswith("shell/") or path == "shell.json":
            full = os.path.join(root, path)
            if os.path.exists(full):
                changed.append(os.path.getmtime(full))
    if not changed:
        return 0
    newest_code = max(changed)
    docs = [os.path.join(root, ".claude", "CLAUDE.md")]
    for folder, _, files in os.walk(os.path.join(root, ".claude", "docs")):
        docs.extend(os.path.join(folder, name) for name in files if name.endswith(".md"))
    newest_docs = max((os.path.getmtime(path) for path in docs if os.path.exists(path)), default=0)
    if newest_docs >= newest_code:
        return 0
    reason = (
        "shell/ changed after .claude/docs was last updated. Before stopping, update the docs this change touches "
        "(map.md for files, architecture.md for data flow, decisions.md for choices, quirks.md for traps, "
        "known-issues.md for debt, roadmap.md for planned work, rules/ for rules the user stated). "
        "If nothing in the docs is affected, touch nothing and stop again."
    )
    print(json.dumps({"decision": "block", "reason": reason}))
    return 0


if __name__ == "__main__":
    sys.exit(main())
