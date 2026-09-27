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

種別スキルは「上流文書の取り込み → 前提質問 → 執筆 → 下流チェック → 自己レビュー → フィードバック記録」の順に進む。既存文書のレビューを頼むと下流チェックだけを回す。上流文書が Confluence 等にある場合は Markdown で貼り付ける（`references/source-intake.md`）。

## 改善ループ

生成文書への指摘のうちスキルの不備に起因するものは `skill-improve` スキルで記録・反映する（dev-docs 専用ではなく全スキル共通）。ログは `~/.claude/skill-feedback/log.jsonl`（ローカル専用・非コミット）、`skill` は `dev-docs:<name>` 形式で記録する。

## 会社テンプレートの取り込み

各スキルの「構成」節は一般型。会社のテンプレートがある場合は、見出し構成と各節の意図だけを汎化して差し替える（社名・製品名・社内 URL は持ち込まない）。
