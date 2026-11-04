# dev-docs 再設計 実装計画

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** dev-docs の 6 スキルを 1 つのスキル `doc` にまとめ、合意フェーズ・共通ルール・種別 reference・ローカルルール・指摘の取り込みを入れる。

**Architecture:** SKILL.md は流れと「いつどの reference を読むか」だけを持つ。規則の中身は `references/` に置き、種別ごとの知識は `references/types/<種別>.md` に分ける。ローカルルールは利用者ディレクトリとプロジェクトの `.claude/dev-docs/` から差分だけを重ねる。

**Tech Stack:** Claude Code プラグイン（Markdown のスキルと references、`plugin.json` の `userConfig`）、bash + python3 の構造テスト、`claude -p` による発火・結果の評価。

**Spec:** `docs/specs/2026-11-04-dev-docs-redesign-design.md`

## Global Constraints

- 公開リポジトリ。ファイル・コミットメッセージに、ローカルのパス（ホーム以下）、メールアドレス、実名、会社名・社内の語彙・顧客名、非公開プロジェクトの名前を入れない
- 本体からローカルや他配布のスキルを名指しで参照しない。境界は役割で書く（「個人用ナレッジの記録」「文の自然さだけの手直し」）
- スキル名は `doc`（`/dev-docs:doc`）。旧 6 スキルは別名を残さず削除する
- プラグインの version は `0.3.0`。`userConfig` のキーは `local_rules_dir`（type `directory`）。`org_templates_dir` は削除する
- 種別の id は `brief` / `prd` / `design-doc` / `dev-schedule` / `research` / `meeting` / `request`。テンプレート・reference のファイル名にこの id を使う
- 利用者ローカルの置き場: `${user_config.local_rules_dir}`。未設定（展開されずに残っている、または空）なら `${CLAUDE_PLUGIN_DATA}`
- プロジェクトのローカルの置き場: プロジェクトルートの `.claude/dev-docs/`。dev-docs は読むだけで、書くのは利用者の了承を得たときだけ
- 新しく書く文章では markdown の表を使わず、見出しと箇条書きで書く。ただし文書のたたき台（テンプレートの骨組み）の中の表はよい
- 変更後は `bash tests/validate.sh`・`bash tests/git-hooks.test.sh`・`bash tests/dev-docs.test.sh` を通す
- コミットは `nesheep5` と noreply アドレス（リポジトリの git config で設定済み）。メッセージに `Claude-Session:` 行を付けない。末尾に `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`
- push はしない。公開前レビュー（CLAUDE.md の手順）を済ませたうえで、作者に確認してから行う
- 評価用の依頼文に業務固有の語を入れない

## Review Focus

- 依頼の見極めの誤り: 1 節の言い回しの修正で合意フェーズを挟む、または新規作成で合意フェーズを飛ばす。利用者はどちらも失敗と感じる（Task 7 の結果評価で両方を確かめる）
- 会社テンプレートがあるときにメッセージ型見出しを当てて、テンプレートの見出し文言を書き換える。テンプレートの見出しはそのまま残し、メッセージ型はその下の小見出しに当てるのが期待（Task 3 の `local-rules.md` に規則、Task 7 に評価ケース）
- 一度限りの指示（「この節は削って」）を好みとして `style.md` に書き込む（Task 7 に評価ケース）
- `local_rules_dir` 未設定で初めて好みを書き込む場面。`${CLAUDE_PLUGIN_DATA}` に書き、設定を勧める案内を 1 回だけ出すのが期待（Task 7 に評価ケース）
- 表現だけの修正を重ねるうちに、事実や出典が文書から抜けていく。調査記録は変わらず、結論を支える事実が抜けたら報告されるのが期待（Task 3 の `research-record.md` と `review.md`、Task 7 のケース 6）
- 他人に渡す資料の依頼で、個人用 wiki の書式（「学び」「未解決の論点」などの節）が混ざる（Task 6 の description 修正と、Task 7 の結果評価で確かめる）

---

### Task 1: 構造テスト

再設計後の形を機械的に確かめるテストを先に書く。この時点では失敗する。

**Files:**
- Create: `tests/dev-docs.test.sh`
- Modify: `.github/workflows/ci.yml`（`git-hooks のテスト` の後に 1 ステップ追加）
- Modify: `CLAUDE.md`（「開発」節のテスト列挙に `bash tests/dev-docs.test.sh` を足す）、`README.md`（「開発」節と「構成」節の tests 列挙）

**Interfaces:**
- Produces: `bash tests/dev-docs.test.sh`。各検査を `ok   <名前>` / `NG   <名前>: <詳細>` で出し、1 つでも NG なら exit 1。後続タスクはこのテストを通すことを完了条件にする

- [ ] **Step 1: テストを書く**

`tests/validate.sh` と同じく bash から python3 のヒアドキュメントを呼ぶ形にする。検査は次の 8 つ。

1. `skills/`: `plugins/dev-docs/skills/` 直下のディレクトリが `doc` だけ
2. `manifest`: `plugin.json` の `version == "0.3.0"`、`userConfig` のキーが `{"local_rules_dir"}` だけで、その `type == "directory"`
3. `old-skill-refs`: `plugins/dev-docs/` 以下とルートの `README.md` に `/dev-docs:(brief|prd|design-doc|dev-schedule|tech-research-doc|tech-writing)\b` が無い
4. `external-skill-refs`: `plugins/dev-docs/` 以下に 旧版で参照していた `skill-improve` `mermaid-to-image` と、他プラグインのスキルを `/<plugin>:<skill>` の形で参照する箇所 が無い
5. `reference-paths`: `plugins/dev-docs/` 以下の `.md` に出てくる `${CLAUDE_PLUGIN_ROOT}/<path>` がすべて実在する
6. `types`: `references/types/` に 7 種別の `<id>.md` があり、各ファイルに `## 必須の情報` `## たたき台の目次` `## 下流に渡すもの` の 3 見出しがある
7. `trigger-cases`: `skills/doc/evals/trigger.json` が `query`（str）と `should_trigger`（bool）だけを持つ要素の配列で、正例 12 件以上・負例 6 件以上
8. `result-cases`: `skills/doc/evals/results.json` が `prompt`（str）と `checks`（空でない str の配列）を持つ要素の配列で、6 件以上

- [ ] **Step 2: 失敗を確かめる**

Run: `bash tests/dev-docs.test.sh`
Expected: exit 1。少なくとも `skills/` `manifest` `types` `trigger-cases` `result-cases` が NG

- [ ] **Step 3: CI・CLAUDE.md・README に登録する**

CI のステップ名は `dev-docs の構造テスト`、run は `bash tests/dev-docs.test.sh`。ルートの `README.md` の「構成」節に `docs/specs/`・`docs/plans/`（設計書と実装計画）の行も足す。

- [ ] **Step 4: コミット**

```bash
git add tests/dev-docs.test.sh .github/workflows/ci.yml CLAUDE.md README.md docs/
git commit -m "dev-docs: 再設計の設計書・実装計画と、再設計後の形を確かめる構造テストを足す"
```

pre-commit は `plugins/` を含まないので validate を走らせない。テストが NG のままコミットしてよい（CI はこのブランチでは赤になる。Task 5 で緑に戻る）。

---

### Task 2: 共通ルール（`references/writing.md`）

種別を問わず全文書に当てる規則。spec の「共通ルール」節がすべてここに入る。

**Files:**
- Create: `plugins/dev-docs/references/writing.md`
- 素材: `plugins/dev-docs/skills/tech-writing/SKILL.md`（本文すべて）、`plugins/dev-docs/skills/tech-research-doc/SKILL.md` の「表現ルール」のうち種別を問わないもの（初見の語の定義、コード参照を使わない、事実には出典・評価には理由）

**Interfaces:**
- Produces: 次の `##` 見出しを持つファイル。Task 3 の `review.md` と Task 5 の SKILL.md がこの見出し名で参照する
  - `## 構成`（ピラミッド構造、冒頭の要約、状況 → 問題 → 問い → 答え、問いを冒頭で示す、事実と解釈を分ける、限界を書く、結論先行、逆茂木型の禁止、トピックセンテンス、セクション間の接続、目的を 1 つに絞る、書かないことを先に決める）
  - `## 見出し`（メッセージ型。条件は spec のとおり。定型の節は名詞のまま。会社テンプレートの見出しは書き換えない）
  - `## 用語`（ユビキタス言語、造語の禁止と合意フェーズでの提案、初出での定義、用語の一貫性）
  - `## 根拠`（調べるときは可能な限り一次情報に当たる。要約・スニペット・記憶で書かない。調べた事実には出典を付け、記載の正当性を後からレビューできるようにする。種別を問わず、調べた事実を含む文書すべてに当てる。書き方の詳細は `${CLAUDE_PLUGIN_ROOT}/references/citation-rules.md`）
  - `## 参照`（ID を振って ID で参照しない。前方参照をしない）
  - `## 文`（一文一義、能動態、無駄な語の削除、事実と意見の書き分け、箇条書きの規律）
  - `## AI 臭さ`（今のアンチパターン 6 つ）

- [ ] **Step 1: 書く**

tech-writing の Before / After の例は残す。今の圧縮パターン表と AI 臭アンチパターン表は、表をやめて箇条書きに直す（「冗長 → 簡潔」の 1 行ずつ）。`## 見出し` には、悪い例（「〜とは？」「はじめに」「まとめ」「推奨は案 B です。ただし前提条件付きです」のような長い主張文）と良い例（「推奨は案 B。移行費用が最も小さい」）を 2 つずつ置く。tech-research-doc にあった「見出しは名詞句」は持ち込まない。

- [ ] **Step 2: 確かめる**

Run: `grep -c '^## ' plugins/dev-docs/references/writing.md` → `7`。`grep -n '名詞句' plugins/dev-docs/references/writing.md` → 「定型の節」の文脈以外に出ない

- [ ] **Step 3: コミット**

```bash
git add plugins/dev-docs/references/writing.md
git commit -m "dev-docs: 種別を問わない共通ルールを references にまとめる"
```

---

### Task 3: 流れを支える references

合意フェーズ・調査記録・自己レビュー・ローカルルール・指摘の取り込みの 5 つと、既存 3 ファイルの手直し。

**Files:**
- Create: `plugins/dev-docs/references/agreement.md`、`research-record.md`、`review.md`、`local-rules.md`、`learning.md`
- Modify: `plugins/dev-docs/references/doc-chain.md`、`source-intake.md`、`citation-rules.md`

**Interfaces:**
- Consumes: Task 2 の `writing.md` の見出し名
- Produces:
  - `agreement.md`: 合意フェーズで示すメッセージの書式。4 項目の名前は「読者と目的」「答える問い」「目次」「用語」。目次は `- <メッセージ型の見出し> — <この節で言うこと 1 行>` の形で階層付き。用語は `- <語>: <意味>（出所: 用語集 / 上流文書 / コード / 発話 / 新規提案）`。「新規提案」の語は合意が取れるまで本文に使わない
  - `research-record.md`: 調査記録の書式と扱い（spec の「調査記録」節のすべて）。置き場の既定は文書と同じ場所の `<文書名>.research.md`、ローカルルール（`style.md` の置き場の指定）で変えられる。書式は `## 問い`（文書が答える問い）→ `## 事実`（1 事実 1 項目。`- <事実>（出典: <citation-rules.md の書き方>、確認日: YYYY-MM-DD）`）→ `## 出典未確認` → `## 解釈`（各項目に、どの事実から導いたか）→ `## 出典一覧`。`## 事実` の項目のうち結論を支えるものには行頭に `【結論の根拠】` を付ける（突き合わせパスで、文書から抜けたかを見る対象）
  - `review.md`: 自己レビューのパス名と順序。目的パス → 見出しパス（見出しだけで論旨が通るか）→ 冒頭パス（冒頭の数行で判断に要ることが分かるか）→ 用語パス（造語・言い換えが無いか、用語集と一致するか）→ 参照パス（ID 参照・前方参照が無いか）→ 冗長パス → AI 臭パス → 出典パス（調べた事実を含む文書すべて。一次情報に当たったか、出典の必須要素がそろっているか）→ 突き合わせパス（調査記録があるとき。文書の事実がすべて調査記録までたどれるか、`【結論の根拠】` の事実が文書から抜けていないか。抜けていたら黙って直さず利用者に報告する）→ 種別パス（種別 reference の「必須の情報」がそろっているか）
  - `local-rules.md`: 読み込み順と置き場。利用者ディレクトリ `U` = `${user_config.local_rules_dir}`（展開されていない・空なら `${CLAUDE_PLUGIN_DATA}`）、プロジェクトディレクトリ `P` = `<プロジェクトルート>/.claude/dev-docs/`。読むファイルは `style.md` `glossary.md` `templates/<id>.md` `templates/<id>.guide.md` `types/<id>.md`。優先は P > U > プラグイン。P は読むだけ。テンプレートがあるときは見出し構成と文言をそのまま使い、メッセージ型はその下の小見出しにだけ当てる。ローカルにスキルを複製しないこと
  - `learning.md`: 指摘の 4 分類（この文書だけ / 好み / ドメインの語 / 一般則）と書き込み先（取り込まない / `U/style.md` / `U/glossary.md` のプロジェクト別の節 / `U/promote-candidates.md`）。項目の書式は下のとおり。返答末尾の通知は `好みに追加: <規則>`（語なら `用語に追加: <語>`、候補なら `本体の候補に追加: <規則>`）。重複は統合、矛盾は書かずに聞く。`style.md` が 30 項目を超えたら統合を提案する。`U` が `${CLAUDE_PLUGIN_DATA}` のときは、最初の書き込みで「設定 `local_rules_dir` を指定すると、アンインストールしても残る」と 1 回だけ伝える（`U/.notified` の有無で判定する）。プロジェクトの用語集 `P/glossary.md` があるときは「チームの用語集にも載せますか」と聞く

`style.md` と `promote-candidates.md` の項目の書式:

```markdown
## <規則を 1 文で>
- なぜ: <理由>
- 例: <指摘を受けた場面と、直す前 → 直した後>
- 追加日: YYYY-MM-DD
```

`glossary.md` の書式（プロジェクト名は作業中のリポジトリのディレクトリ名）:

```markdown
## <プロジェクト名>
- **<語>**: <意味>。使わない言い方: <言い換え>（追加日: YYYY-MM-DD）
```

- [ ] **Step 1: 4 ファイルを書く**

- [ ] **Step 2: 既存 3 ファイルを直す**

`doc-chain.md`: スキル列（`/dev-docs:<name>`）を種別 id に置き換え、表をやめて見出しと箇条書きにする。打ち合わせ資料と依頼書は連鎖の外にあると 1 行書く。「種別スキルの段階4」の言い回しを「流れの下流チェック」に直す。`source-intake.md` と `citation-rules.md`: 「種別スキル」「tech-writing」「tech-research-doc」への言及を `writing.md` / 種別 id に直す。`citation-rules.md` の冒頭の適用範囲（「調査資料・DesignDoc・スパイク検証記録など」）を「種別を問わず、調べた事実を含む文書すべて」に広げ、「一次情報を優先する（公式ドキュメント・コード・原典の社内文書・元データ。要約やスニペットで知った事実は原典まで遡る）」を 4 区分の前に足す。

- [ ] **Step 3: 確かめる**

Run: `bash tests/dev-docs.test.sh`
Expected: `reference-paths` と `external-skill-refs` が、references 配下については NG を出さない（`skills/` の旧スキル由来の NG は残ってよい）

- [ ] **Step 4: コミット**

```bash
git add plugins/dev-docs/references/
git commit -m "dev-docs: 合意フェーズ・自己レビュー・ローカルルール・指摘の取り込みの references を足す"
```

---

### Task 4: 種別の reference（7 つ）

**Files:**
- Create: `plugins/dev-docs/references/types/brief.md`、`prd.md`、`design-doc.md`、`dev-schedule.md`、`research.md`、`meeting.md`、`request.md`
- 素材: 旧 `skills/brief` `prd` `design-doc` `dev-schedule` `tech-research-doc` の SKILL.md

**Interfaces:**
- Consumes: Task 3 の `local-rules.md`（テンプレートの扱い）、`doc-chain.md`
- Produces: 各ファイルが冒頭 1 行の「この文書が答える問い」と、`## 必須の情報` `## たたき台の目次` `## 下流に渡すもの` の 3 見出しを持つ。前提質問があれば `## 前提質問` を足してよい。たたき台の目次は並び順の押しつけではなく、合意フェーズで組み替える出発点だと明記する

- [ ] **Step 1: 旧スキルの 5 種を移す**

各旧 SKILL.md の「前提質問」「構成」「各節の要点」を移す。「進め方」（段階 1〜6）と、別配布の改善記録のスキルへの言及は移さない（流れは SKILL.md が持つ）。たたき台の目次の見出しはメッセージ型の書き方の指示（例: `## <背景と課題を 1 文で言い切る>`）に直す。design-doc の `mermaid-to-image` の記述は「Confluence 等に貼るときは画像化が要ることがある」と役割で書く。`research.md` には、今の「案を比べる型」に加えて「事実 → 考慮すべき要件 → 現状とのギャップ」の型をたたき台の目次として並べ、どちらを使うかは「読者が選択肢から選ぶ」か「現状の何が足りないかを議論する」かで決めると書く。

- [ ] **Step 2: 打ち合わせ資料と依頼書を最小限で書く**

`meeting.md`: 必須の情報は「打ち合わせで決めること・聞くこと」「参加者が事前に知っておくこと」「相手に聞く質問（それぞれ、なぜ聞くか）」。たたき台の目次は 決めること → 前提 → 論点ごとの叩き台 → 質問事項。`request.md`: 必須の情報は「渡す作業と完了の状態」「背景（なぜ頼むか）」「期限と優先度」「判断を任せる範囲と、相談してほしい範囲」「参照先」。下流に渡すものは「完了の状態」。

- [ ] **Step 3: 確かめる**

Run: `bash tests/dev-docs.test.sh`
Expected: `types` が ok

- [ ] **Step 4: コミット**

```bash
git add plugins/dev-docs/references/types/
git commit -m "dev-docs: 種別ごとの知識を 7 つの reference に移す"
```

---

### Task 5: スキル本体と manifest

**Files:**
- Create: `plugins/dev-docs/skills/doc/SKILL.md`、`plugins/dev-docs/skills/doc/evals/trigger.json`、`plugins/dev-docs/skills/doc/evals/results.json`
- Delete: `plugins/dev-docs/skills/{brief,prd,design-doc,dev-schedule,tech-research-doc,tech-writing}/`
- Modify: `plugins/dev-docs/.claude-plugin/plugin.json`、`plugins/dev-docs/README.md`、ルートの `README.md`（プラグイン一覧の行）

**Interfaces:**
- Consumes: Task 2〜4 のすべてのファイル名と見出し名
- Produces: `/dev-docs:doc`

- [ ] **Step 1: SKILL.md を書く**

frontmatter の `name: doc`。description に入れること: 開発にまつわる文書（設計書・DesignDoc・要件・PRD・Brief・調査資料・検討資料・打ち合わせ資料・叩き台・依頼書・スケジュール・README・ADR・手順書）の作成・修正・構成の手直し・推敲・レビュー。他人に渡す資料ならこのスキルを使う。対象外は個人用ナレッジの記録・文の自然さだけの手直し・社外向けの技術記事。他スキルの名前は書かない。

本文は spec の「流れ」の 6 段階をそのまま持ち、各段階で読む reference を `${CLAUDE_PLUGIN_ROOT}/references/...` で示す。段階 1 で `local-rules.md` に従ってローカルルールを読み、表現だけの修正か中身の修正かを見分ける。段階 2 と 4 は `research-record.md`、段階 3 は `agreement.md`、段階 5 は `review.md`、段階 6 は `doc-chain.md`。spec の「出力先」の優先順 5 つは SKILL.md に直接書く（短いので reference に分けない）。指摘を受けたときは `learning.md`。種別の判定に迷ったら、候補を 1 つ挙げて合意フェーズの「読者と目的」で確かめる（作り手の判断として spec に残っていた項目の決定）。他人に渡す資料に、個人用ナレッジの書式（学び・未解決の論点などの節）を持ち込まないと 1 行書く。SKILL.md は 120 行以内に収める。

- [ ] **Step 2: 発火の評価ケースを書く**

`trigger.json` に正例 12 件以上・負例 6 件以上。正例に含める型: 新規の DesignDoc / PRD / Brief / スケジュール、調査結果をチームに共有する資料にまとめる、外部の担当者との打ち合わせの叩き台、相手に聞く質問事項の整理、メンバーへの依頼書、既存資料の構成を読みやすく直す、既存資料のレビュー、「推敲して冗長さを削って」（開発の文書）、README の書き直し。負例: 自分用の wiki に知見を残す、文の自然さだけを直す（「AI っぽさを消して」）、社外ブログの記事を書く、コードのリファクタ、英訳、コミットメッセージを書く。旧 6 スキルの `evals/trigger.json` から使えるものは移してよい。`results.json` は Task 7 の結果評価の 6 ケース（下）を `prompt` と `checks` で書く。

- [ ] **Step 3: 旧スキルを削除し、manifest と README を直す**

`plugin.json`: `version` を `0.3.0`、`description` を「開発にまつわる文書の作成・修正・レビューを、読者と目次の合意から始めて支援する。共通ルールに利用者・プロジェクトのローカルルールを重ねる」の趣旨に、`userConfig` を `local_rules_dir`（title「ローカルルールの置き場」、description「好み（style.md）・用語集（glossary.md）・会社テンプレート（templates/）を置くディレクトリ。空なら plugin のデータディレクトリを使う（アンインストールで消える）」）に置き換える。

`plugins/dev-docs/README.md`: 初めて読む利用者が、何ができるかに加えて「なぜこう作ったか」まで分かるように、全面的に書き直す（作者の依頼）。表を使わず、見出しと箇条書きで書く。見出しはこのプラグイン自身の規則（メッセージ型、ID で参照しない）に従う。次の節をこの順で置く。

1. 冒頭の要約（3〜4 行）: 開発にまつわる文書の作成・修正・レビューを 1 つのスキルで受ける。書く前に読者と目次を合意し、共通ルールに利用者・プロジェクトのローカルルールを重ねる。指摘を受けるほど好みに沿う
2. 設計の考え方。それぞれ「何をするか」と「なぜか」を 1〜2 文で
   - 読者・答える問い・目次・用語を、書く前に合意する（種別ごとの固定構成は、文書ごとの議論の筋に合わないことがあるため）
   - 結論を先に置き、概要から詳細へ分解する。見出しはメッセージ型で、見出しだけで論旨がたどれる（ブログ調の構成・タイトルを避けるため）
   - そのドメインで使われている語を使い、造語や言い換えをしない。新しい語は合意してから使う
   - ID を振って ID で参照しない（読者に前後の行き来をさせないため）
   - 一次情報に当たり、出典を付けて、正当性を後からレビューできるようにする
   - 調査と資料作成を分ける（表現の修正を重ねても、調査内容が薄まらないようにするため）
   - ビジネス文書（ピラミッド構造、冒頭の要約）と論文（問いの明示、事実と解釈の区別、限界）の作法を取り入れている
3. 使い方: `/dev-docs:doc` と、明示しなくても文書の依頼で呼ばれること。流れの 6 段階（新規・大きな改稿・小さな修正・レビューで、どの段階を回すか）
4. 対応している種別: 7 種別をそれぞれ「答える問い」付きで。種別に当たらない文書も共通ルールで書けること。種別ごとの書き方は使いながら育てること
5. 出力先: spec の優先順 5 つと、調査記録の置き場
6. ローカルルール: 3 層と優先順、各ファイルの役割（`style.md` `glossary.md` `templates/` `types/` `promote-candidates.md`）、`local_rules_dir` の設定と未設定時の動き、プロジェクトの層は読むだけであること、ローカルにスキルを複製しないこと（正本が 2 つになるため）
7. 指摘の取り込み: 4 分類と書き込み先、返答末尾の通知、取り違いの取り消し方
8. 他のスキルとの境界: 対象外のもの（個人用ナレッジの記録、文の自然さだけの手直し、社外向けの技術記事）を役割で書く。本体は他のスキルを名指ししない、ローカルのスキルから dev-docs を指すのはよい、という依存の向き
9. 0.2 からの移行: 旧 6 スキルの廃止と、`org_templates_dir` から `local_rules_dir` への移し方（3 行）
10. 保守: 共通ルールは `writing.md` が正。種別を足すときは `types/`・`doc-chain.md`・`trigger.json` を同時に直す。評価ケースは `skills/doc/evals/`。テストは `bash tests/dev-docs.test.sh`

公開リポジトリなので、作者のセッション履歴の数字や、作者のマシンに固有の置き場は書かない。

ルートの `README.md` は、プラグイン一覧の行を新しい説明に直し、表をやめて箇条書きにする。

- [ ] **Step 4: 確かめる**

Run: `bash tests/dev-docs.test.sh && bash tests/validate.sh && bash tests/git-hooks.test.sh`
Expected: 3 つとも exit 0。`dev-docs.test.sh` は 8 検査すべて ok

- [ ] **Step 5: コミット**

```bash
git add -A plugins/dev-docs README.md
git commit -m "dev-docs: 6 スキルを doc 1 つにまとめる"
```

---

### Task 6: 個人用ナレッジのスキルとの競合を減らす（任意、リポジトリの外）

利用者の手元に個人用ナレッジを書くスキルがある場合は、そちらの description で「他人に渡す資料」を対象外にすると、発火の競合が減る。リポジトリの外の作業なので、この計画では扱わない。

---

### Task 7: 評価と仕上げ

**Files:**
- 出力: `tmp/eval/`（gitignore 済み）
- 変更が要れば Task 2〜5 のファイル

- [ ] **Step 1: 発火の評価**

worktree の plugin を読ませるため、環境変数 `CLAUDE_CODE_PLUGIN_DIRS=<worktree>/plugins/dev-docs` を付けて実行する（`--plugin-dir` 相当で、同名のインストール済み plugin を置き換える。https://code.claude.com/docs/en/plugins/loading.md §Name conflicts）。

Run: `plugins/dev-docs/skills/doc/evals/trigger.json` の各ケースを、`CLAUDE_CODE_PLUGIN_DIRS=<worktree>/plugins/dev-docs` を付けた `claude -p` で複数回流し、Skill の呼び出しを数える。結果は `tmp/` に保存する
Expected: 正例は全件が過半数の回で発火し、負例は全件が 1 回も発火しない。外れたら description を直して再実行する（`--out` の結果で外れたケースだけ流してよい）

- [ ] **Step 2: 結果の評価**

`results.json` の 6 ケースを、`claude -p` に流す。ファイルを書くので、`--cwd` は `tmp/eval/<ケース名>/` の使い捨てディレクトリにする。`local_rules_dir` は `--settings` で `tmp/eval/<ケース名>/local/` を指す（`pluginConfigs` の書式は https://code.claude.com/docs/en/settings-reference.md#pluginconfigs で確かめる）。ケース 4 だけ `local_rules_dir` を設定しない。

1. 新規の検討資料（選択肢 3 つの技術選定）: 合意フェーズの 4 項目が本文より先に出る / 目次の見出しがメッセージ型で、「はじめに」「〜とは？」「まとめ」が無い / ID 参照が無い
2. 既存資料の 1 文の言い回しの修正: 合意フェーズが出ない / 直した箇所以外を書き換えない
3. 会社テンプレート（`local/templates/design-doc.md` に見出し 5 つの架空テンプレートを置く）で DesignDoc の新規作成: テンプレートの見出し文言がそのまま残る / 小見出しはメッセージ型
4. 書き方の指摘を含む 2 往復（1 回目で文書を作らせ、2 回目で「要件に ID を振らないで」と「この節は削って」を同時に伝える）、`local_rules_dir` 未設定: ID の指摘だけが `style.md` に書かれる / 「この節は削って」は書かれない / 返答に `好みに追加:` がある / 設定を勧める案内が出る。評価後に `${CLAUDE_PLUGIN_DATA}` に書かれたファイルを削除する
5. 調査結果をチームに共有する資料にまとめる（公開されている OSS ライブラリ 2 つの比較など、一次情報に当たれる題材）: 「学び」「未解決の論点」の節が無い / 冒頭の数行に結論がある / 調べた事実に、URL + セクション名か `path:line` の出典が付き、末尾に確認日付きの出典一覧がある / 文書の隣に `<文書名>.research.md` ができ、書いた場所が返答で伝えられる
6. ケース 5 の続きで「内容は合っているので、もっと短く、柔らかい表現にして」と頼む 2 往復目: `<文書名>.research.md` が 1 往復目から変わらない（差分なし）/ `【結論の根拠】` の事実が文書に残るか、抜けたものが返答で報告される / 出典の付いていない断定が増えていない

Expected: 全ケースの checks を満たす。満たさない項目は、該当する reference か SKILL.md を直して再実行する

- [ ] **Step 3: 全テストとセルフレビュー**

Run: `bash tests/dev-docs.test.sh && bash tests/validate.sh && bash tests/git-hooks.test.sh`
Expected: 3 つとも exit 0

その後、PR 前のセルフレビューの観点で `git diff origin/main...HEAD` を読む。

- [ ] **Step 4: コミット**

評価で直したファイルがあれば:

```bash
git add plugins/dev-docs
git commit -m "dev-docs: 評価で見つかった振る舞いのずれを直す"
```

- [ ] **Step 5: 公開前レビューの準備**

CLAUDE.md の「公開前レビュー」1〜4 を行う（範囲は `origin/main..HEAD`、新しいサブエージェントに `git log -p --format='%an <%ae>%n%B' origin/main..HEAD` の出力だけを渡す）。記録は `$(git rev-parse --git-common-dir)/publish-review/<HEAD の sha>`。push はせず、作者に確認を求めて止まる
