#!/usr/bin/env bash
# dev-docs プラグインの形を確かめる構造テスト。スキルの振る舞いは claude -p の評価で見る
set -uo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

python3 - "$REPO_DIR" <<'EOF'
import json, os, re, sys

repo = sys.argv[1]
plugin = os.path.join(repo, "plugins", "dev-docs")
fail = False

def report(name, problems):
    global fail
    if problems:
        fail = True
        for p in problems:
            print(f"NG   {name}: {p}")
    else:
        print(f"ok   {name}")

def md_files(root):
    for d, _, files in os.walk(root):
        for f in files:
            if f.endswith(".md"):
                yield os.path.join(d, f)

def read(path):
    with open(path, encoding="utf-8") as f:
        return f.read()

def rel(path):
    return os.path.relpath(path, repo)

TYPES = ["brief", "prd", "design-doc", "dev-schedule", "research", "meeting", "request"]

# skills/ 直下は doc だけ
skills_dir = os.path.join(plugin, "skills")
found = sorted(d for d in os.listdir(skills_dir) if os.path.isdir(os.path.join(skills_dir, d)))
report("skills/", [] if found == ["doc"] else [f"doc だけのはずが {found}"])

# manifest
problems = []
manifest = json.load(open(os.path.join(plugin, ".claude-plugin", "plugin.json"), encoding="utf-8"))
if manifest.get("version") != "0.3.0":
    problems.append(f"version が 0.3.0 でない: {manifest.get('version')}")
uc = manifest.get("userConfig", {})
if set(uc) != {"local_rules_dir"}:
    problems.append(f"userConfig のキーが local_rules_dir だけでない: {sorted(uc)}")
elif uc["local_rules_dir"].get("type") != "directory":
    problems.append("local_rules_dir の type が directory でない")
report("manifest", problems)

# 旧スキルのスラッシュコマンドを参照していない
old = re.compile(r"/dev-docs:(brief|prd|design-doc|dev-schedule|tech-research-doc|tech-writing)\b")
problems = []
for path in list(md_files(plugin)) + [os.path.join(repo, "README.md")]:
    for i, line in enumerate(read(path).splitlines(), 1):
        if old.search(line):
            problems.append(f"{rel(path)}:{i}")
report("old-skill-refs", problems)

# 本体から他のスキルを名指ししない（依存はローカル → dev-docs の向きだけ）。
# 旧版で参照していた 2 つと、他プラグインの /<plugin>:<skill> 形式の参照を拾う
external = re.compile(r"skill-improve|mermaid-to-image|`/(?!dev-docs:)[a-z0-9-]+:[a-z0-9-]+")
problems = []
for d, _, files in os.walk(plugin):
    for f in files:
        path = os.path.join(d, f)
        try:
            text = read(path)
        except UnicodeDecodeError:
            continue
        for i, line in enumerate(text.splitlines(), 1):
            if external.search(line):
                problems.append(f"{rel(path)}:{i}")
report("external-skill-refs", problems)

# ${CLAUDE_PLUGIN_ROOT}/<path> が実在する。<id> のような置き換え前提のパスは対象外
ref = re.compile(r"\$\{CLAUDE_PLUGIN_ROOT\}/([^\s`)\]'\"]+)")
problems = []
for path in md_files(plugin):
    for i, line in enumerate(read(path).splitlines(), 1):
        for m in ref.finditer(line):
            target = m.group(1).rstrip("。、.,:")
            if "<" in target:
                continue
            if not os.path.exists(os.path.join(plugin, target)):
                problems.append(f"{rel(path)}:{i} → {target}")
report("reference-paths", problems)

# references は展開されないので、${CLAUDE_PLUGIN_ROOT} 以外の変数で置き場を決めない
problems = []
for path in md_files(os.path.join(plugin, "references")):
    for i, line in enumerate(read(path).splitlines(), 1):
        if re.search(r"\$\{(user_config\.|CLAUDE_PLUGIN_DATA|CLAUDE_PROJECT_DIR)", line):
            problems.append(f"{rel(path)}:{i}")
report("reference-vars", problems)

# 公開ファイルにホーム以下のパスを入れない。Claude Code の設定置き場（~/.claude）だけは一般の場所として許す
local_path = re.compile(r"(/Users|/home)/[^/\s<>`]+|~/(?!\.claude\b)")
problems = []
for root in [plugin, os.path.join(repo, "docs")]:
    for path in md_files(root):
        for i, line in enumerate(read(path).splitlines(), 1):
            if local_path.search(line):
                problems.append(f"{rel(path)}:{i}")
report("local-paths", problems)

# 依頼の見極めの基準と、小さな修正での自己レビューの範囲が書かれている
skill_text = read(os.path.join(skills_dir, "doc", "SKILL.md"))
problems = []
if "見出しの構成か順序が変わるなら大きな改稿" not in skill_text:
    problems.append("大きな改稿と小さな修正を分ける基準が無い")
if "直した箇所にだけ" not in skill_text:
    problems.append("小さな修正での自己レビューの範囲が無い")
report("request-scope", problems)

# 種別の reference
problems = []
for t in TYPES:
    path = os.path.join(plugin, "references", "types", f"{t}.md")
    if not os.path.isfile(path):
        problems.append(f"{t}.md が無い")
        continue
    heads = set(re.findall(r"^## (.+?)\s*$", read(path), re.M))
    for h in ["必須の情報", "たたき台の目次", "下流に渡すもの"]:
        if h not in heads:
            problems.append(f"{t}.md に「## {h}」が無い")
report("types", problems)

def load_cases(name):
    path = os.path.join(skills_dir, "doc", "evals", name)
    if not os.path.isfile(path):
        return None, [f"{rel(path)} が無い"]
    try:
        return json.load(open(path, encoding="utf-8")), []
    except json.JSONDecodeError as e:
        return None, [f"{rel(path)} が JSON でない: {e}"]

# 発火の評価ケース
cases, problems = load_cases("trigger.json")
if cases is not None:
    if not isinstance(cases, list):
        problems.append("配列でない")
    else:
        for i, c in enumerate(cases):
            if not (isinstance(c, dict) and set(c) == {"query", "should_trigger"}
                    and isinstance(c["query"], str) and isinstance(c["should_trigger"], bool)):
                problems.append(f"{i} 番目の形が違う")
        pos = sum(1 for c in cases if isinstance(c, dict) and c.get("should_trigger") is True)
        neg = sum(1 for c in cases if isinstance(c, dict) and c.get("should_trigger") is False)
        if pos < 12:
            problems.append(f"正例が 12 件未満: {pos}")
        if neg < 6:
            problems.append(f"負例が 6 件未満: {neg}")
report("trigger-cases", problems)

# 結果の評価ケース
cases, problems = load_cases("results.json")
if cases is not None:
    if not isinstance(cases, list):
        problems.append("配列でない")
    else:
        for i, c in enumerate(cases):
            if not (isinstance(c, dict) and isinstance(c.get("prompt"), str)
                    and isinstance(c.get("checks"), list) and c["checks"]
                    and all(isinstance(x, str) and x for x in c["checks"])):
                problems.append(f"{i} 番目の形が違う")
        if len(cases) < 6:
            problems.append(f"6 件未満: {len(cases)}")
report("result-cases", problems)

sys.exit(1 if fail else 0)
EOF
