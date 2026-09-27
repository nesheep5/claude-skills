# ケースの形式

`claude plugin eval` の `prompt.md` ＋ `graders/*.md` の形に寄せ、prompt-eval 固有の項目を `prompt_eval:` の下に足す。

```
evals/prompt-eval/
  md-link-answer/
    prompt.md
    graders/
      link.md        # type: regex
      answer.md      # type: llm
```

## prompt.md

```markdown
---
name: md-link-answer
allowed_tools: [Read, Glob, Grep]   # 既定は読み取りだけ。書き込みを許すと worktree や cwd が変わる
max_turns: 15                        # 任意
cwd: ~/src/some-repo                 # 任意。global は既定で空の一時ディレクトリ、repo は worktree の根
prompt_eval:
  kind: change                       # change（今回の変更）| regression（回帰用に残したもの）
  expected_difference: >
    after は答えの md ファイルを file:// の markdown リンクで示す。
    before は裸のパスかコード書式で示す。
  added_in: <変更のコミット>          # regression に昇格させたときに書く
---
このリポジトリで、プラグインを追加するときの手順が書かれたドキュメントはどれ？
```

本文が被験の Claude に渡す依頼。ユーザーが実際に打ちそうな文にする。規則の名前や「規則に従って」を依頼に書くと、規則が無くても依頼文だけで振る舞いが変わり、before との差が消える。

`cwd` は依頼に必要なファイルがある場所を指す。repo モードで `cwd` を書くとリポジトリ内のパスとして扱い、各腕の worktree 内の同じ位置に読み替える。

読める frontmatter は、スカラー、`[a, b]` のリスト、1 段の入れ子、`>` / `|` の複数行だけ。

## graders/*.md

すべての grader が通った実行を「合格」と数える（重みは付けない）。ファイル名が grader 名になる。

### type: regex（機械判定、費用なし）

```markdown
---
type: regex
match: contains      # contains | not_contains | count:N（N 回以上）
target: final        # final（最終応答）| trace（ツール呼び出しと途中の発話を含む記録）
---
\]\(file:///[^)]*\.md\)
```

本文が正規表現（Python の `re`、複数行モード）。`pattern:` を frontmatter に書いてもよい。

使いどころ: 決まった書式の有無、禁止したコマンドが trace に出ないこと（`target: trace` ＋ `not_contains`）、特定ツールを使ったこと（trace には `[tool_use <ツール名>] <入力 JSON>` の形で並ぶ）。

### type: llm（判定役の Claude が採点）

```markdown
---
type: llm
focus: final         # final | trace
---
答えとして示した md ファイルが、file:// の絶対パスを持つ markdown リンクになっている。
説明の中で付随的に触れたファイルはリンクでなくてよい。
```

本文が採点基準。判定役（既定 sonnet、`--safe-mode` で CLAUDE.md を読まない）が 1 実行につき 1 回採点する（`--judge-votes` で多数決にできる）。判定が構造化出力にならなかった票は無効票になり、`--judge-retries` 回まで引き直す。それでも有効票が足りなければ、その実行は無効（inconclusive の原因）になる。生の出力は実行ごとの `judge/` に残る。

基準の書き方:

- 観察できる行動で書く。「丁寧に説明している」ではなく「実行前にユーザーに確認を求め、確認が無いまま push していない」
- 形式・見出し・言い回しを合否に使わない。after の文面に似ているかではなく、規則が求める行動が起きたかを見る
- 境界を書く。付随的な言及をどう扱うか、部分的に満たした場合はどうか。書かないと判定役ごとにぶれる
- 1 grader に 1 観点。複数の観点を混ぜると、どれで落ちたか分からない

## 判別しない grader

change ケースでは、ランナーは grader ごとに before / after × 回数の合否表を作り、両腕で常に通る（`always-pass-both`）・常に落ちる（`always-fail-both`）grader に警告を付ける。change ケースで警告が出た grader は、差を測れていない。基準を締めるか、依頼を before で落ちるものに変える。
