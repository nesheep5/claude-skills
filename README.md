# claude-skills

[![CI](https://github.com/nesheep5/claude-skills/actions/workflows/ci.yml/badge.svg)](https://github.com/nesheep5/claude-skills/actions/workflows/ci.yml)

nesheep5 の自作 Claude Code プラグイン集（plugin marketplace）。

## 使い方

```
/plugin marketplace add nesheep5/claude-skills
/plugin install <plugin>@nesheep5
```

プラグイン内のスキルは `/<plugin>:<skill>` で明示的に起動できる。

## プラグイン一覧

- `dev-docs`: 開発にまつわる文書（設計書・要件・調査資料・打ち合わせ資料・依頼書など）の作成・修正・レビューを、読者と目次の合意から始めて支援する。共通ルールに利用者・プロジェクトのローカルルールを重ね、指摘を受けるほど好みに沿う。詳しくは [plugins/dev-docs/README.md](plugins/dev-docs/README.md)

## 構成

    .claude-plugin/marketplace.json   マーケットプレイスの目録
    plugins/<name>/                    1 ディレクトリ = 1 プラグイン
      .claude-plugin/plugin.json
      skills/<name>/SKILL.md
    git-hooks/                         公開前の検査（pre-commit・pre-push）
    tests/                             validate.sh・git-hooks.test.sh・dev-docs.test.sh
    docs/specs/  docs/plans/           設計書と実装計画
    .github/workflows/ci.yml           push と PR で tests/ を走らせる

## 開発

作者のマシンでは、このリポジトリのクローンをローカルのパスでマーケットプレイスとして登録し、元の場所から読み込む。

```
claude plugin marketplace add <このリポジトリのパス>
```

- 編集は次のセッションか `/reload-plugins` で反映される。ローカルのパスで登録したマーケットプレイスは cache に複製せず元の場所から読むため、version を上げる必要は無い
- 変更後は `bash tests/validate.sh`・`bash tests/git-hooks.test.sh`・`bash tests/dev-docs.test.sh` を通す

## 公開前の検査

公開リポジトリなので、コミットと push の前に次を検査する（`git config core.hooksPath git-hooks` で有効にする）。

- gitleaks による秘匿情報の検出（pre-commit・pre-push）
- author・committer が GitHub の noreply アドレスであること（pre-push）
- push する差分の判断レビュー（pre-push がレビューの記録を確かめる）。語のリストでは守らず、差分を読んで個人・組織・非公開の情報が無いかを判断する。手順は CLAUDE.md

## ライセンス

MIT（[LICENSE](LICENSE)）
