#!/usr/bin/env bash
# mermaid を高DPI画像に変換するラッパー。
# mmdc(mermaid-cli) は内部で Chromium を必要とするが、Homebrew 版には同梱されない。
# そのため Chrome 実行ファイルを自動検出し PUPPETEER_EXECUTABLE_PATH に渡す。
#
# 使い方:
#   render.sh -i <入力> -o <出力> [-s scale] [-b 背景] [-t テーマ]
#
# 入力が .md なら中の全 mermaid ブロックを連番(out-1.png, out-2.png...)で出力する。
# 入力が .mmd なら 1 図 1 画像で出力する。
#
# 例:
#   render.sh -i diagram.mmd -o diagram.png            # 単体図 → 高DPI PNG
#   render.sh -i notes.md   -o notes.png               # md内の全図 → notes-1.png ...
#   render.sh -i d.mmd -o d.png -b transparent         # 透明背景
#   render.sh -i d.mmd -o d.svg                         # SVG出力(拡張子で切替)

set -euo pipefail

# --- デフォルト値 ---
# scale=3 はベクター相当の鮮明さを狙った高DPI。Confluence で拡大しても荒れにくい。
scale=3
background=white
theme=default
input=""
output=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    -i|--input)      input="$2"; shift 2 ;;
    -o|--output)     output="$2"; shift 2 ;;
    -s|--scale)      scale="$2"; shift 2 ;;
    -b|--background) background="$2"; shift 2 ;;
    -t|--theme)      theme="$2"; shift 2 ;;
    *) echo "不明な引数: $1" >&2; exit 1 ;;
  esac
done

if [[ -z "$input" || -z "$output" ]]; then
  echo "エラー: -i <入力> と -o <出力> は必須です" >&2
  exit 1
fi

if ! command -v mmdc >/dev/null 2>&1; then
  echo "エラー: mmdc が見つかりません。'brew install mermaid-cli' でインストールしてください" >&2
  exit 1
fi

# --- Chrome 実行ファイルの自動検出 ---
# 既に環境変数が設定済みならそれを尊重する。
chrome="${PUPPETEER_EXECUTABLE_PATH:-}"
if [[ -z "$chrome" ]]; then
  for candidate in \
    "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
    "/Applications/Chromium.app/Contents/MacOS/Chromium" \
    "/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge" \
    "$(command -v google-chrome-stable 2>/dev/null || true)" \
    "$(command -v google-chrome 2>/dev/null || true)" \
    "$(command -v chromium 2>/dev/null || true)"; do
    if [[ -n "$candidate" && -x "$candidate" ]]; then
      chrome="$candidate"
      break
    fi
  done
fi

if [[ -z "$chrome" ]]; then
  echo "エラー: Chrome/Chromium が見つかりません。" >&2
  echo "Google Chrome をインストールするか、PUPPETEER_EXECUTABLE_PATH を設定してください。" >&2
  exit 1
fi

PUPPETEER_EXECUTABLE_PATH="$chrome" mmdc \
  -i "$input" \
  -o "$output" \
  -s "$scale" \
  -b "$background" \
  -t "$theme"
