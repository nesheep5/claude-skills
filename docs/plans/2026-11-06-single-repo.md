# dev-docs を単独リポジトリにする

- 作成日: 2026-11-06
- 対象: リポジトリ全体（`nesheep5/claude-skills` → `nesheep5/dev-docs`）

## 要約

プラグイン集として作った `nesheep5/claude-skills` を、dev-docs だけを載せる単独リポジトリにする。新しいリポジトリは作らず改名し、マーケットプレイス名を `nesheep5` から `dev-docs` に変える。今後のスキルは、それぞれ別のリポジトリで作る。

## なぜ分けるか

- スキルが増えると、開発時の文脈（CLAUDE.md・設計書・テスト）と PR が混ざる。スキルごとにリポジトリを分けて範囲を閉じる
- dev-docs を単体のツールとして人に勧め、必要な人に見つけてもらいたい。README・About・Issue・リリースを dev-docs だけのものにする

## 決めたこと

- **名前**: リポジトリ名・プラグイン名・マーケットプレイス名をすべて `dev-docs` にそろえる。マーケットプレイス名は利用者ごとに 1 つしか登録できないため、単独リポジトリを複数持つと `nesheep5` のままでは衝突する。GitHub のコード検索では、マーケットプレイス名を `dev-docs` にしているものは無かった（プラグイン名が `dev-docs` のものは 5 件あるが、ID が `dev-docs@<マーケットプレイス名>` なので衝突しない）
- **移し方**: GitHub で改名する。履歴と PR を引き継げる
- **プラグインの置き場**: `plugins/dev-docs/` に残す。ルートに上げるとリポジトリ全体がプラグインになり、tests・docs・git-hooks まで利用者の環境に複製される
- **見つけてもらう入口**: 探す人は日本語（「設計書 作成 claude code スキル」）で探す。topics は英小文字しか使えないので、日本語の語は About の説明と README の冒頭に入れる

## 作業

### 1. リポジトリの中身

1. `marketplace.json` の `name` を `dev-docs` にし、`metadata.description` を dev-docs の説明にする
2. `plugins/dev-docs/README.md` をルートの `README.md` に移す。導入コマンドを `nesheep5/dev-docs`・`dev-docs@dev-docs` に、CI バッジを新しいリポジトリ名に直す。開発と公開前の検査の節は README の末尾に残す
3. CLAUDE.md の「このリポジトリの性質」を dev-docs の単独リポジトリとして書き直し、「1 ディレクトリ = 1 プラグイン」を消す
4. `bash tests/validate.sh`・`bash tests/git-hooks.test.sh`・`bash tests/dev-docs.test.sh` を通す
5. 公開前レビューを経て PR にし、マージする

### 2. GitHub 側

6. リポジトリ名を `dev-docs` に変える
7. About の説明を「設計書・仕様書・調査資料の作成を支援する Claude Code スキル（プラグイン）」とし、topics に `claude-code`・`claude-code-plugin`・`claude-skills` を付ける

### 3. 作者の端末

8. データディレクトリ（`~/.claude/plugins/data/dev-docs-nesheep5/`）の好みを `~/.claude` の外へ写す。マーケットプレイスを外すと、データディレクトリも消える
9. ローカルのクローンを新しいリポジトリ名の場所に移し、remote の URL を更新する
10. 旧マーケットプレイス `nesheep5` を外し、移した後のパスでマーケットプレイスを追加して `dev-docs@dev-docs` を入れる。`local_rules_dir` に 8 の写し先を指定する
11. `/dev-docs:write` が呼べ、好みが読まれることを確かめる

## やらないこと

- 共通の仕組み（pre-push・公開前レビュー・テスト）のテンプレートリポジトリは、2 つ目のスキルを作るときに用意する
- `npx skills` や他のエージェントへの対応。dev-docs は Claude Code 固有の機能（`${CLAUDE_PLUGIN_ROOT}`・`userConfig`・`${CLAUDE_PLUGIN_DATA}`）に依存している
- リリースタグ

## 出典

- 相対パスの source と、ルートを指す `"./"`: https://code.claude.com/docs/en/plugins/marketplace-reference.md（Relative path plugin source）
- マーケットプレイス名は利用者ごとに 1 つ、予約名: 同上（Marketplace file、Reserved names）
- プラグイン ID とデータディレクトリの場所: https://code.claude.com/docs/en/plugins/components.md（Reference plugin paths and store data）、https://code.claude.com/docs/en/plugins/loading.md（Find plugins on disk）
- 確認日: 2026-11-06
