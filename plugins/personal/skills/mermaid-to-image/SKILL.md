---
name: mermaid-to-image
description: mermaid の図を高DPI の PNG（または SVG）画像に変換する。スクリーンショットと違いベクター相当の鮮明さで、拡大しても荒れない。Confluence や Wiki など mermaid 非対応の場所に図を貼りたいとき、md ファイル内の mermaid を画像にしたいとき、あるいは Claude 自身が会話中に作った mermaid をそのまま画像ファイルにしてほしいと頼まれたときに使う。「mermaid を画像に」「図を PNG にして」「この diagram をエクスポート」「Confluence に貼る図を作って」のような依頼で必ず使うこと。手動でスクショを撮らせてはいけない。
---

# Mermaid を高DPI画像に変換

mermaid のコードを **荒れない高解像度の画像** に変換する。背景には mermaid-cli (`mmdc`) を使い、
Chromium でレンダリングするため表示はブラウザのプレビューと同等。スクリーンショットでは
拡大すると荒れるが、この方式は scale 3 の高DPI出力なので Confluence などに貼って拡大しても鮮明。

## 基本の使い方

同梱スクリプト `scripts/render.sh` を呼ぶ。Chrome の場所を自動検出するので、利用側は入力と出力を渡すだけでよい。

```bash
bash <skill_dir>/scripts/render.sh -i <入力> -o <出力>
```

`<skill_dir>` はこの SKILL.md があるディレクトリ。

### 入力の種類で挙動が変わる

- **`.md` ファイル**: 中の **すべての** ` ```mermaid ` ブロックを抽出し、連番で出力する。
  `-o notes.png` を指定すると `notes-1.png`, `notes-2.png` ... が生成される。
- **`.mmd` ファイル**: mermaid コード単体。1 図 → 1 画像。

## Claude が作った図を画像にする場合（主用途）

会話中に mermaid を書いた／書くよう頼まれて「画像にして」と言われたときは、
そのコードを一時 `.mmd` ファイルに書き出してから変換する。中間ファイルでユーザーを驚かせないよう、
出力先は依頼の文脈に沿った場所（カレントや指定パス）にし、不要な一時ファイルは後で消す。

```bash
# 1. mermaid コードを一時ファイルに書く（例）
cat > /tmp/diagram.mmd <<'EOF'
flowchart TD
    A[開始] --> B{条件}
    B -->|yes| C[処理]
    B -->|no| D[終了]
EOF

# 2. 画像化
bash <skill_dir>/scripts/render.sh -i /tmp/diagram.mmd -o ./diagram.png
```

生成後は画像のパスをユーザーに伝える。複数図なら連番ファイル名をすべて挙げる。

## オプション

| 目的 | 渡し方 | 既定 |
| --- | --- | --- |
| 解像度（高DPI） | `-s 3`（数値を上げるほど高精細・大きいファイル） | `3` |
| 背景色 | `-b white` / `-b transparent` / `-b '#F0F0F0'` | `white` |
| テーマ | `-t default` / `forest` / `dark` / `neutral` | `default` |
| 出力形式 | `-o out.svg` のように **拡張子で切替**（png/svg/pdf） | png |

### 背景の選び方
- **Confluence やドキュメントに貼る**なら `white`（既定）が無難。ページ背景と馴染み、ダークテーマの図でも文字が読める。
- **背景色を選ばずどこにでも重ねたい**なら `-b transparent`。ただしダークなテーマ（`-t dark`）と透明背景を併用すると、明るい場所で文字が見えなくなる点に注意。

### SVG が欲しいと言われたら
出力拡張子を `.svg` にするだけ。SVG は完全なベクターなので拡大で一切劣化しない。
ただし Confluence のバージョンによっては SVG 添付の表示にクセがあるため、貼り先が SVG に対応しているか不明なら高DPI PNG の方が無難、と一言添えるとよい。

## 前提と失敗時の対処

- `mmdc` が必要（`brew install mermaid-cli`）。スクリプトが無ければエラーを返す。
- レンダリングに Chrome/Chromium が必要。スクリプトが主要なパスを自動検出するが、
  見つからない場合は `PUPPETEER_EXECUTABLE_PATH=/path/to/chrome` を設定して再実行する。
- 図がうまく出ない場合、まず mermaid コード自体が正しいか（プレビューで描画できるか）を疑う。
  構文エラーは `mmdc` のエラー出力に現れる。
