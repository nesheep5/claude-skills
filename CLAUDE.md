# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## このリポジトリの性質

**公開**リポジトリ。nesheep5 の自作 Claude Code プラグインのマーケットプレイス（name: `nesheep5`）。

## 書いてはいけないもの

ファイル・コミットメッセージ・author のどこにも、次を入れない。

- ローカルのパス（ホームディレクトリ以下）
- メールアドレス、実名
- 会社名・社内の語彙・顧客名
- 非公開のリポジトリやプロジェクトの名前、そこでの具体的な作業内容

語のリストでは守らない（書いていない語は素通りし、リスト自体が秘密になるため）。push の前の判断レビューで守る。

## 公開前レビュー

push の前に必ず行う。pre-push が記録の有無を確かめ、無ければ止める。

1. push する範囲を決める（初回や force push なら `main` 全体、通常は `origin/main..HEAD`）
2. **新しいサブエージェント**に、`git log -p --format='%an <%ae>%n%B' <範囲>` の出力だけを渡し、「個人・組織・非公開のプロジェクトを特定できる情報、ローカルの環境に依存する記述が無いか」を判断させる。作業の文脈を知らない読み手の方が見落としにくい。サブエージェントにはファイルの変更・コミット・push をさせない
3. 指摘があれば、語を消すのではなく一般化して書き直し、1 からやり直す
4. 問題が無ければ、`.git/publish-review/<push する HEAD の sha>` に要点を書く（何を見て、何が無かったか、指摘と直した内容）。`.git` の中なので公開されない
5. push はユーザーに確認してから行う

人が自分で確かめて push するときは、`PUBLISH_REVIEWED=1 git push` で記録を省ける。gitleaks と作者の検査は省けない。

## 準備

```bash
git config core.hooksPath git-hooks
git config user.name nesheep5
git config user.email <GitHub の noreply アドレス>
```

コミットは `nesheep5` と GitHub の noreply アドレスで行う（pre-push が author・committer を確かめる）。コミットメッセージに `Claude-Session:` の行（会話の URL）を付けない。`Co-Authored-By` は付けてよい。

## 開発

- 1 ディレクトリ = 1 プラグイン（`plugins/<name>/`）。`marketplace.json` のソースは `./plugins/<name>` の相対パスで書く
- 作者のマシンでは、クローンをローカルのパスでマーケットプレイスとして登録し、元の場所から読ませる。GitHub の形で登録すると cache に複製され、編集が反映されない
- 変更後は `bash tests/validate.sh`（`claude plugin validate`）と `bash tests/git-hooks.test.sh` を通す
- push は公開と同じ意味なので、毎回ユーザーに確認する
