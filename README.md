# claude-skills

nesheep5 の自作 Claude Code プラグイン集（plugin marketplace）。

## 使い方

```
/plugin marketplace add nesheep5/claude-skills
/plugin install <plugin>@nesheep5
```

プラグイン内のスキルは `/<plugin>:<skill>` で明示的に起動できる。

## プラグイン一覧

| プラグイン | 中身 |
|---|---|
| `dev-docs` | Brief・PRD・DesignDoc・開発スケジュール・検討資料を、文書間の連鎖を保って作成・レビューする。土台の文章術（tech-writing）を含む |
| `personal` | 小さな汎用スキルの詰め合わせ。`skill-improve`（スキルへの指摘を記録・集計して SKILL.md に反映する）、`mermaid-to-image`（Mermaid を画像にする） |

## 構成

    .claude-plugin/marketplace.json   マーケットプレイスの目録
    plugins/<name>/                    1 ディレクトリ = 1 プラグイン
      .claude-plugin/plugin.json
      skills/<name>/SKILL.md
    git-hooks/                         公開前の検査（pre-commit・pre-push）
    tests/                             validate.sh・git-hooks.test.sh

## 開発

作者のマシンでは、このリポジトリのクローンをローカルのパスでマーケットプレイスとして登録し、元の場所から読み込む。

```
claude plugin marketplace add <このリポジトリのパス>
```

- 編集は次のセッションか `/reload-plugins` で反映される。ローカルのパスで登録したマーケットプレイスは cache に複製せず元の場所から読むため、version を上げる必要は無い
- 変更後は `bash tests/validate.sh` と `bash tests/git-hooks.test.sh` を通す

## 公開前の検査

公開リポジトリなので、コミットと push の前に次を検査する（`git config core.hooksPath git-hooks` で有効にする）。

- gitleaks による秘匿情報の検出（pre-commit・pre-push）
- author・committer が GitHub の noreply アドレスであること（pre-push）
- push する差分の判断レビュー（pre-push がレビューの記録を確かめる）。語のリストでは守らず、差分を読んで個人・組織・非公開の情報が無いかを判断する。手順は CLAUDE.md
