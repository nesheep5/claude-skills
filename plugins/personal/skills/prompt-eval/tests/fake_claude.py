#!/usr/bin/env python3
"""テスト用の偽の claude。

被験側: 読める指示（--append-system-prompt-file か cwd の CLAUDE.md）に RULE_LINK があれば
「[x](file:///x.md)」を、無ければ裸のパスを返す。FAKE_FLAKY=1 なら 3 回に 1 回ルールを無視する。
judge 側（--json-schema 付き）: DATA に file:/// があれば PASS。FAKE_JUDGE_FLAKY に置いたファイルが無い
最初の 1 回だけ、構造化出力の無い結果を返す（無効票の引き直しの確認用）。
自動読み込み（CLAUDE_CODE_DISABLE_CLAUDE_MDS が無いとき）は、cwd の CLAUDE.md と FAKE_GLOBAL_MD を読む。
"""
import json
import os
import sys
from pathlib import Path

args = sys.argv[1:]
if args == ["--version"]:
    print("0.0.0 (fake)")
    sys.exit(0)

prompt = args[args.index("-p") + 1]


def opt(name):
    return args[args.index(name) + 1] if name in args else None


if "--json-schema" in args:
    flaky = os.environ.get("FAKE_JUDGE_FLAKY")
    if flaky and not Path(flaky).exists():
        Path(flaky).write_text("x")
        print(json.dumps({"type": "result", "is_error": False, "subtype": "success", "total_cost_usd": 0.001}))
        sys.exit(0)
    ok = "file:///" in prompt.split("[BEGIN DATA]", 1)[-1]
    print(json.dumps({"type": "result", "is_error": False, "total_cost_usd": 0.001,
                      "structured_output": {"pass": ok, "reason": "fake", "evidence": "fake"}}))
    sys.exit(0)

if os.environ.get("CLAUDECODE"):
    print("nested", file=sys.stderr)
    sys.exit(1)

instructions = ""
if opt("--append-system-prompt-file"):
    instructions += Path(opt("--append-system-prompt-file")).read_text()
if not os.environ.get("CLAUDE_CODE_DISABLE_CLAUDE_MDS"):
    for p in (Path("CLAUDE.md"), Path(os.environ.get("FAKE_GLOBAL_MD", "/nonexistent"))):
        if p.exists():
            instructions += p.read_text()

counter = Path(os.environ["FAKE_COUNTER"]) if os.environ.get("FAKE_COUNTER") else None
n = 0
if counter:
    n = int(counter.read_text() or 0) if counter.exists() else 0
    counter.write_text(str(n + 1))

if os.environ.get("FAKE_USAGE_LIMIT"):
    print(json.dumps({"type": "result", "is_error": True, "subtype": "error",
                      "result": "Claude usage limit reached", "total_cost_usd": 0}))
    sys.exit(0)

follow = "RULE_LINK" in instructions and not (os.environ.get("FAKE_FLAKY") and n % 3 == 0)
text = "See [x.md](file:///x.md)" if follow else "See `x.md`"
print(json.dumps({"type": "assistant", "message": {"content": [
    {"type": "tool_use", "name": "Read", "input": {"file_path": "x.md"}},
    {"type": "text", "text": text}]}}))
print(json.dumps({"type": "result", "is_error": False, "subtype": "success",
                  "result": text, "total_cost_usd": 0.01}))
