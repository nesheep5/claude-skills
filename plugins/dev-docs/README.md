# dev-docs

開発ドキュメント5種（Brief / PRD / 検討資料 / DesignDoc / 開発スケジュール）を、文書間の連鎖を保って作成・レビューするプラグイン。

```
Brief ──▶ PRD ──▶ DesignDoc ──▶ 開発スケジュール
                     ▲
               検討資料
```

| スキル | 問い | 起動 |
|---|---|---|
| brief | なぜやるか | `/dev-docs:brief` |
| prd | 何を提供するか | `/dev-docs:prd` |
| tech-research-doc | どれに進むか / どの技術方針を採るか | `/dev-docs:tech-research-doc` |
| design-doc | どう作るか | `/dev-docs:design-doc` |
| dev-schedule | いつ何を出すか | `/dev-docs:dev-schedule` |
| tech-writing | 文章術（全スキルの土台） | 他スキルから自動で併用 |

## 使い方

種別スキルは「上流文書の取り込み → 前提質問 → 執筆 → 下流チェック → 自己レビュー → フィードバック記録」の順に進む。既存文書のレビューを頼むと下流チェックだけを回す。上流文書が Confluence 等にある場合は Markdown で貼り付ける（`references/source-intake.md`）。調査事実の出典の書き方は `references/citation-rules.md` に従う。

## 改善ループ

生成文書への指摘のうちスキルの不備に起因するものは `skill-improve` スキル（別配布。入っていれば）で記録・反映する（dev-docs 専用ではなく全スキル共通）。ログは `~/.claude/skill-feedback/log.jsonl`（ローカル専用・非コミット）、`skill` は `dev-docs:<name>` 形式で記録する。

## 組織テンプレートの取り込み

各スキルの「構成」節は一般型。組織（会社）指定のテンプレートは、組織固有の情報を含むためこのリポジトリには入れず、ローカルにだけ置く。

- 置き場: プラグインの設定 `org_templates_dir`（ディレクトリ）で指定する。有効化したときの設定ダイアログか `/config` で入れる。未設定なら一般構成で書く
- `<skill>.md`: テンプレート原本。種別スキルは執筆時にこのパスを確認し、あれば見出し構成をそのまま骨組みに使う
- `<skill>.guide.md`（任意）: 原本の各見出しを埋めるための記載ルール・横断ルール・追加の前提質問。原本と同じく組織の構成が読み取れるので、ローカルにだけ置く

対応しているのは design-doc。他スキルも同じ方式で追加する。

## 保守

- 種別スキル4つ（brief / prd / design-doc / dev-schedule）は同じ共通手順を持つ。文書間の引き渡し情報は `references/doc-chain.md` が正。構成を変えるときはここと各 SKILL.md の「下流チェック」を同時に直す
- `tech-writing` は全スキルの土台。他スキルは `/dev-docs:tech-writing` の自己レビューパスを参照するので、パスを増減したら呼び出し側の記述も確かめる
- 出典の書き方は `references/citation-rules.md` が正。tech-writing・tech-research-doc・design-doc が参照する
- 組織テンプレートを読み込む仕組みだけをここに書く。テンプレート由来の見出し構成・記載ルールは、汎化したものも持ち込まない
- フィードバックの記録は `skill-improve` スキルがあるときだけ行う。無い環境でも手順が成り立つように書く
- 各スキルの `evals/trigger.json` は発火の評価ケース（`query` と `should_trigger`）。description を変えたら、使うべき依頼と似ているが使うべきでない依頼の両方で発火を確かめる。例文に業務固有の語を入れない
