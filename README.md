# claude-skills

nesheep5 の自作 Claude Code プラグイン集（plugin marketplace）。単一スキルもプラグインとして配布する。

## 使い方

```
/plugin marketplace add nesheep5/claude-skills
/plugin install <plugin>@nesheep5
```

プラグイン内のスキルは `/<plugin>:<skill>` で明示起動できる（説明文による自動起動はプラグイン化の影響を受けない）。

## プラグイン一覧

（まだ無い。[claude-config](https://github.com/nesheep5/claude-config) で育てたものを順次昇格する）

## 構成

    .claude-plugin/marketplace.json   マーケットプレイスの目録
    plugins/<name>/                    1ディレクトリ = 1プラグイン
      .claude-plugin/plugin.json
      skills/<name>/SKILL.md           （agents/ hooks/ 等はあれば）
    tests/validate.sh                  claude plugin validate による検証

## 開発（本人向け）

- 育成は private の claude-config で行い、`/promote-skill <name>` でここへ移す。手順は claude-config 側の promote-skill スキルに従う
- 自分のマシンでは claude-config の `install.sh` が `plugins/<name>` を `~/.claude/skills/<name>` へ symlink し、`<name>@skills-dir` として自動ロードする。**このマシンで marketplace からも install しないこと**（同名プラグインが二重ロードされる）
- 変更後は `bash tests/validate.sh` を通す
