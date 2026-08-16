# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## このリポジトリは何か

nesheep5 の自作 Claude Code プラグインを配布する **plugin marketplace**（public）。
スキルの育成は private の [claude-config](https://github.com/nesheep5/claude-config) で行い、公開できる状態になったものを `/promote-skill <name>` でここへ移す。**このリポジトリ内でスキルを新規作成・育成しない**（成果物の置き場であり、開発の場ではない）。

## コマンド

```bash
bash tests/validate.sh          # 変更後は必ず通す（marketplace + 各プラグインの検証）
claude plugin validate .        # marketplace.json 単体（plugins が空の間は warning が出る＝正常）
claude plugin validate plugins/<name> --strict   # プラグイン1件だけ検証
```

`tests/validate.sh` は 3 段階: (1) marketplace 本体を非 strict で検証、(2) `plugins/*/` を strict で検証、(3) `marketplace.json` の各 `source` が `plugin.json` を持つ実在ディレクトリを指すか python3 で突合。いずれか失敗で exit 1。

## 構成の要点

- `.claude-plugin/marketplace.json` — 目録。`plugins[]` の各エントリは `name` / `source`（`./plugins/<name>`）/ `description` / `version` の **4 フィールドのみ**。
- `plugins/<name>/` — 1 ディレクトリ = 1 プラグイン。`.claude-plugin/plugin.json` + `skills/<name>/SKILL.md`。**単一スキルでも必ずプラグインとして包む**ため、明示起動名は `/<name>:<name>` になる。
- プラグイン追加時は `marketplace.json`・`plugins/<name>/`・`README.md` の「プラグイン一覧」の 3 箇所を揃えて更新する（promote-skill の手順が正）。
- ルート直下の `skills/` は空ディレクトリ（git 未追跡の残骸）。ここにスキルを置かない。

## 運用上の注意

- このマシンでは claude-config の `install.sh` が `plugins/<name>` を `~/.claude/skills/<name>` へ symlink し、`<name>@skills-dir` として自動ロードしている。**marketplace 経由で install しない**（同名プラグインが二重ロードされる）。`claude plugin list` で `<name>@skills-dir` が 1 件だけであることを確認する。
- public リポジトリなので、追加するスキルに社名・内部 URL・ローカルパス（`/Users/...`）等の環境依存・秘匿情報が混入していないか、コミット前に確認する。
- push は本人の判断で行う（public への push はユーザーに確認してから）。
