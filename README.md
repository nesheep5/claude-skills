# dev-docs

[![CI](https://github.com/nesheep5/dev-docs/actions/workflows/ci.yml/badge.svg)](https://github.com/nesheep5/dev-docs/actions/workflows/ci.yml)

開発にまつわる文書（設計書・要件・調査資料・打ち合わせ資料・依頼書など）を書き、更新し、推敲し、レビューする Claude Code プラグイン。commit message や PR 説明のような、コードの変更に付く短い文書も扱う。スキルは `/dev-docs:write` の 1 つで、新規作成と大きな改稿では、書く前に読者と目次を利用者と合意してから本文に進む。書き方の指摘を受けると利用者のローカルルールに取り込み、次の文書から反映する。

```
/plugin install dev-docs --marketplace nesheep5/dev-docs
```

## できること

次の 7 つの種別は、種別ごとに必須の情報・たたき台の目次・次の文書に渡すものを持つ（`plugins/dev-docs/references/types/`）。括弧内は、ローカルルールでテンプレートを置くときに使う種別の id。

- Brief（`brief`）: なぜやるか
- PRD（`prd`）: 何を提供するか
- DesignDoc（`design-doc`）: どう作るか
- 開発スケジュール（`dev-schedule`）: いつ何を出すか
- 検討資料（`research`）: 調査をもとに何を選ぶか。案を比べる型と、事実 → 要件 → ギャップの型を持つ
- 打ち合わせ資料（`meeting`）: 打ち合わせで何を決め、何を聞くか
- 依頼書（`request`）: 誰に何をどの状態まで頼むか

README・ADR・手順書・仕様書・リリースノートのように、どの種別にも当たらない文書は、共通ルール（すべての文書に当てる書き方の規則）と合意だけで書く。

commit message・PR 説明・エージェント向けの指示（CLAUDE.md・SKILL.md など）・コードコメントは付随文書として扱い、リポジトリの規約に合わせて軽い流れで書く（`plugins/dev-docs/references/attached-text.md`）。

依頼の例:

- 「認証まわりの設計書を書いて」
- 「ログ基盤の 3 案を比べる検討資料を作って。判断するのは開発責任者」
- 「明日の打ち合わせで先方に聞くことをまとめて」
- 「この PRD をレビューして。DesignDoc を書くのに足りない情報を挙げて」
- 「この README が読みづらいので直して」
- 「TTL を変えたので、設計書の該当する記述を最新化して」
- 「今の変更内容で commit message を書いて」

## インストール

Claude Code 2.1.275 以降なら、セッションの中で次の 1 行を実行する。マーケットプレイスの追加とインストールが同時に済む。

```
/plugin install dev-docs --marketplace nesheep5/dev-docs
```

それより前の版では、2 段階で入れる。

```
/plugin marketplace add nesheep5/dev-docs
/plugin install dev-docs@dev-docs
```

入れたら、設定 `local_rules_dir`（ローカルルールの置き場）に `~/.claude` の外のディレクトリを指定することを勧める。

```
/plugin configure dev-docs@dev-docs
```

未設定のままだと、プラグインのデータディレクトリ（`~/.claude/plugins/data/` の下）を使う。ここはアンインストールすると消える。また `~/.claude` の下にあるため、書き込みのたびに許可を求められたり、非対話の実行では拒否されたりすることがある。

## 使い方

`/dev-docs:write` に続けて依頼を書く。明示しなくても、文書の作成・修正・レビューを頼めば呼ばれる。

依頼の種類によって、途中で起きることが変わる。

- 新規作成と大きな改稿（見出しの構成か順序が変わる直し）: 本文を書く前に、読者と目的・答える問い・目次・用語の 4 つを示し、了承を待つ。目次は種別のたたき台から始め、その文書の論旨に合わせて組み替える
- 小さな修正: 合意を省き、頼まれた箇所だけを直す。ほかの箇所で見つけた問題は直さず、返答で指摘する
- レビュー: 文書を書き換えず、どこが・なぜ問題で・どう直すかを返す
- 付随文書: 合意・調査記録・次の文書へのチェックを省く。先にリポジトリの規約（PR テンプレート、`git log` の書きぶり、CLAUDE.md など）を読み、書いた内容を差分やコードと突き合わせる

調べることがあれば、書く前に一次情報に当たり、結果を調査記録に残す。調査記録は、調べた事実と出典を文書とは別に持つファイルで、文書はここから書き起こす。表現の直しを重ねても、調べた内容が薄まらないようにするためだ。表現だけの修正なら、調べ直さず調査記録にも触れない。

書き終えたら自己レビューを回す。見出しが選んだ型でそろっているか、冒頭で判断に要ることが分かるか、用語・参照・出典は正しいか、調査記録と食い違っていないかを確かめる。最後に、次の文書（PRD → DesignDoc など）に渡す情報がそろっているかを確かめ、欠けは未決事項に判断者つきで載せる。

## 出力先

次の順で決め、書いた場所を毎回返答で伝える。

1. 依頼で示された場所
2. 既存の文書の修正なら、その文書の場所
3. ローカルルール（`style.md`）で指定した置き場
4. プロジェクトの慣習（`docs/` の下に同じ種別の文書があるなど）
5. どれにも当たらなければ `docs/<種別の id>/YYYY-MM-DD-<テーマ>.md`

調査記録は、文書の隣に `<文書名>.research.md` で置く。ツール専用の隠しディレクトリやリポジトリの外は既定にしない。人に読ませる文書なので、見つけやすく、共有・レビューできる場所に置く。

## ローカルルール

ローカルルールは、プラグインの規則に重ねる、利用者やプロジェクトごとの差分。置き場は 2 つあり、重なったときはプロジェクト > 利用者 > プラグインの順で優先する。

### 置き場

- 利用者のローカル: 設定 `local_rules_dir` のディレクトリ。未設定なら、プラグインのデータディレクトリ
- プロジェクトのローカル: プロジェクトのルートの `.claude/dev-docs/`。コミットしてチームで共有するものとして扱い、dev-docs は読むだけにする。書き込むのは、利用者に聞いて了承を得たときだけ

### 置けるファイル

どちらの置き場にも、次のファイルを置ける。

- `style.md`: 書き方の好み。文書や調査記録の置き場の指定もここに書く
- `glossary.md`: 用語集。利用者のローカルでは、プロジェクトごとの節に分かれる
- `templates/<種別の id>.md`: 会社やチームの文書テンプレート。見出しの構成と文言はそのまま使い、選んだ見出しの型はその下の小見出しにだけ当てる
- `templates/<種別の id>.guide.md`: テンプレートの各見出しを埋めるための記載ルールと、追加の前提質問
- `types/<種別の id>.md`: プラグインに無い種別の追加、またはプラグインの種別の上書き
- `promote-candidates.md`: プラグイン本体に昇格させたい一般則の候補（利用者のローカルだけ）

ローカルにスキルを丸ごと複製しない。複製すると正本が 2 つになり、どちらが効いているか追えなくなる。変えたいところだけを上のファイルに書く。

### 指摘の取り込み

セッション中に書き方の指摘を受けると、dev-docs は文書を直すのと同時に、指摘を次の 4 つに振り分ける。

- この文書だけの話（「この節は削って」）: 取り込まない
- 利用者の好み（「ID を振らないで」）: 利用者のローカルの `style.md` に追記する
- ドメインの語（「その言い方ではなく『〜』と呼んでいる」）: 利用者のローカルの `glossary.md` の、作業中のプロジェクトの節に追記する。プロジェクトのローカルに用語集があれば、そちらにも載せるかを聞く
- 誰にでも効く一般則: `promote-candidates.md` に追記する。プラグイン本体には書き込まない

利用者のローカルへは確認を挟まずに書き込み、返答の末尾に「好みに追加: 〜」のように 1 行で知らせる。取り違いなら「それは今回だけ」と言えば消える。既存の項目と矛盾するときは、書き込まずに聞く。dev-docs が確認なしに書き込むのは、文書・調査記録と、この利用者のローカルだけだ。

## 書き方の方針

正本は `plugins/dev-docs/references/writing.md`（共通ルール）にある。要点は次のとおり。

- 冒頭の数行で、結論と読者に求めることを渡す。背景を積み上げてから本題に入らない
- 見出しの型は読者の読み方で選ぶ。既定は節で扱うものの名前を書くラベル型で、結論は冒頭の要約と各節の最初の 1 文に置く。検討資料のように読者が通読して判断する文書だけ、見出しに結論を書くメッセージ型にする
- そのドメインで使われている語を使う。比喩や造語は使わず、新しい語は合意してから使う
- 要件や論点に ID を振って ID で参照しない。短い名前で呼び続ける
- 一次情報に当たり、読者が後から確かめられる形で出典を付ける
- 調査と資料作成を分け、文書は調査記録から書き起こす
- ビジネス文書からピラミッド構造と冒頭の要約を、論文から問いの明示・事実と解釈の区別・限界の明記を取り入れる

## 向いていない用途

- 個人用ナレッジやメモへの記録
- 文の自然さ（語感・AI っぽさ）だけの手直し
- 社外向けの技術記事・ブログ。導入から入る読み物の構成が正当な文書で、dev-docs の規則と衝突する
- コミットや PR 作成のような操作そのもの。文面を書く・直す依頼でだけ呼ばれる

## 更新

このマーケットプレイスは、利用者の側で自動更新が既定でオフになっている。新しい版は、シェルで次のコマンドを実行して取り込む。

```
claude plugin update dev-docs@dev-docs
```

### マーケットプレイス名の変更

リポジトリを `nesheep5/claude-skills` から `nesheep5/dev-docs` に、マーケットプレイス名を `nesheep5` から `dev-docs` に変えた。プラグインの ID が `dev-docs@nesheep5` から `dev-docs@dev-docs` に変わるため、入れ直す。

1. `local_rules_dir` が未設定なら、データディレクトリ（`~/.claude/plugins/data/dev-docs-nesheep5/`）の `style.md` などを `~/.claude` の外へ写す。旧マーケットプレイスを外すと、このディレクトリも消える
2. `/plugin marketplace remove nesheep5` で旧マーケットプレイスを外す
3. 「インストール」の手順で入れ直し、`local_rules_dir` に 1 の写し先を指定する

### 0.4 からの移行

- スキル名を `doc` から `write` に変えた。`/dev-docs:doc` では呼べないので、`/dev-docs:write` で呼ぶ
- 既存の文書の更新・追記と、付随文書（commit message・PR 説明・エージェント向けの指示・コードコメント）の文面でも呼ばれるようにした

### 0.2 からの移行

- 0.2 の 6 スキル（`brief` / `prd` / `design-doc` / `dev-schedule` / `tech-research-doc` / `tech-writing`）は 1 つにまとめた（今の `write`）。旧スキルの名前では呼べない
- 設定 `org_templates_dir` は `local_rules_dir` に置き換えた。新しい設定にディレクトリを指定し、旧ディレクトリの `<種別>.md` と `<種別>.guide.md` をその下の `templates/` に移す
- `tech-research-doc` 向けのテンプレートは `templates/research.md` に名前を変える

## 困ったとき

### ローカルルールへの書き込みのたびに許可を求められる

`local_rules_dir` が未設定で、`~/.claude` の下のデータディレクトリに書き込んでいる。`/plugin configure dev-docs@dev-docs` で、`~/.claude` の外のディレクトリを指定する。

### 取り込まれた好みを取り消したい

取り込んだ直後なら「それは今回だけ」と言う。後からなら、利用者のローカルの `style.md` や `glossary.md` から該当する項目を消す。

### 古いスキル名で呼べない

0.2 の 6 スキルは 0.3 で 1 つにまとめ、0.5 で名前を `doc` から `write` に変えた。`/dev-docs:write` で呼ぶか、スキル名を付けずにそのまま依頼する。

## 開発

作者向けの情報。

### 構成

    .claude-plugin/marketplace.json   マーケットプレイスの目録（dev-docs だけを載せる）
    plugins/dev-docs/                  プラグイン本体
      .claude-plugin/plugin.json
      skills/write/SKILL.md
      references/
    git-hooks/                         公開前の検査（pre-commit・pre-push）
    tests/                             validate.sh・git-hooks.test.sh・dev-docs.test.sh
    docs/specs/  docs/plans/           設計書と実装計画
    .github/workflows/ci.yml           push と PR で tests/ を走らせる

プラグイン本体をリポジトリのルートに置かないのは、tests・docs・git-hooks まで利用者の環境に複製しないため。

### 手元での動かし方

作者のマシンでは、このリポジトリのクローンをローカルのパスでマーケットプレイスとして登録し、元の場所から読み込む。

```
claude plugin marketplace add <このリポジトリのパス>
```

- 編集は次のセッションか `/reload-plugins` で反映される。ローカルのパスで登録したマーケットプレイスは cache に複製せず元の場所から読むため、version を上げる必要は無い
- 変更後は `bash tests/validate.sh`・`bash tests/git-hooks.test.sh`・`bash tests/dev-docs.test.sh` を通す

### 保守

- 共通ルールの正本は `plugins/dev-docs/references/writing.md`。付随文書の規則は `plugins/dev-docs/references/attached-text.md` にあり、共通ルールのうち文のレベルのものだけを当てる。自己レビューのパス（`plugins/dev-docs/references/review.md`）は、その見出しの名前で参照している
- 種別を足すときは、`plugins/dev-docs/references/types/<種別の id>.md`、`plugins/dev-docs/references/doc-chain.md`、`plugins/dev-docs/skills/write/SKILL.md` の種別の一覧、`plugins/dev-docs/skills/write/evals/trigger.json` を同時に直す
- references の中の `${...}` は展開されない。展開されるのはスキル本文だけなので、ローカルの置き場の実際の値は SKILL.md の「置き場の解決」で渡している
- プラグイン本体は、他のスキルを名前で参照しない。公開しているプラグインから、利用者の手元にしかないスキルへの依存を作らないため。手元のスキルの側から dev-docs を名指しするのはよい（例: 個人用 wiki のスキルの説明に「他人に渡す資料は dev-docs を使う」と書く）
- 評価ケースは `plugins/dev-docs/skills/write/evals/`。`trigger.json` は発火（`query` と `should_trigger`）、`results.json` は振る舞い（`prompt` と `checks`）。description を変えたら発火を確かめ直す。例文に業務固有の語を入れない

## 公開前の検査

公開リポジトリなので、コミットと push の前に次を検査する（`git config core.hooksPath git-hooks` で有効にする）。

- gitleaks による秘匿情報の検出（pre-commit・pre-push）
- author・committer が GitHub の noreply アドレスであること（pre-push）
- push する差分の判断レビュー（pre-push がレビューの記録を確かめる）。語のリストでは守らず、差分を読んで個人・組織・非公開の情報が無いかを判断する。手順は CLAUDE.md

## ライセンス

MIT（[LICENSE](LICENSE)）
