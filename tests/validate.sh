#!/usr/bin/env bash
# marketplace.json と各プラグインの manifest を claude plugin validate で検証する
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FAIL=0

# marketplace 本体（plugins が空の間は warning が出るので非 strict）
claude plugin validate "$REPO_DIR" || FAIL=1

# 各プラグインは strict
for plugin in "$REPO_DIR"/plugins/*/; do
  [ -f "$plugin/.claude-plugin/plugin.json" ] || continue
  claude plugin validate "${plugin%/}" --strict || FAIL=1
done

# marketplace.json の source が実在するディレクトリを指しているか
python3 - "$REPO_DIR" <<'EOF'
import json, os, sys
repo = sys.argv[1]
mkt = json.load(open(os.path.join(repo, ".claude-plugin", "marketplace.json")))
bad = [p["name"] for p in mkt["plugins"] if not os.path.isfile(os.path.join(repo, p["source"], ".claude-plugin", "plugin.json"))]
if bad:
    print("NG: source が plugin.json を持たない:", bad); sys.exit(1)
print("ok: marketplace.json の source はすべて実在する")
EOF

exit $FAIL
