#!/bin/bash
# git-hooks（pre-commit・pre-push）のテスト。一時リポジトリで走らせる
REPO=$(cd "$(dirname "$0")/.." && pwd)
T="$REPO/tmp/hooks-test"; rm -rf "$T"; mkdir -p "$T"
git init -q -b main "$T/r"
mkdir -p "$T/r/git-hooks"; cp "$REPO/git-hooks/pre-commit" "$REPO/git-hooks/pre-push" "$T/r/git-hooks/"
NOREPLY="tester <1+tester@users.noreply.github.com>"
G() { git -C "$T/r" "$@"; }
G config user.name tester; G config user.email 1+tester@users.noreply.github.com; G config core.hooksPath /dev/null
fail=0
check() { if [ "$1" = "$2" ]; then echo "ok   $3"; else echo "NG   $3 (expect=$1 got=$2)"; fail=1; fi; }
pc() {  # 事前にステージしておく
  if (cd "$T/r" && SKIP_VALIDATE=1 bash git-hooks/pre-commit) >/dev/null 2>&1; then echo pass; else echo fail; fi
  G reset -q
}
pp() {  # HEAD を新しいブランチとして push する想定。$@ は env の追加
  local sha; sha=$(G rev-parse HEAD)
  if printf 'refs/heads/main %s refs/heads/main 0000000000000000000000000000000000000000\n' "$sha" \
      | (cd "$T/r" && env "$@" bash git-hooks/pre-push) >/dev/null 2>&1; then echo pass; else echo fail; fi
}
review() { mkdir -p "$T/r/.git/publish-review"; echo "要点: 差分を読み、会社・個人・非公開の情報は無かった" > "$T/r/.git/publish-review/$(G rev-parse HEAD)"; }

echo "hello" > "$T/r/a.md"; G add a.md
check pass "$(pc)" "pre-commit: 無害な内容は通す"

G add a.md; G commit -q -m "add a"
check fail "$(pp)" "pre-push: レビューの記録が無ければ止める"
check pass "$(pp PUBLISH_REVIEWED=1)" "pre-push: PUBLISH_REVIEWED=1 なら記録なしでも通す"
review
check pass "$(pp)" "pre-push: レビュー済みで author が noreply なら通す"
: > "$T/r/.git/publish-review/$(G rev-parse HEAD)"
check fail "$(pp)" "pre-push: 中身が空のレビュー記録は認めない"

G commit -q --amend -m "add a" --author "Real Name <real@example.com>"; review
check fail "$(pp)" "pre-push: author が noreply でなければ止める"
G -c user.email=real@example.com commit -q --amend -m "add a" --author "$NOREPLY"; review
check fail "$(pp)" "pre-push: committer が noreply でなければ止める"
check fail "$(pp PUBLISH_REVIEWED=1)" "pre-push: PUBLISH_REVIEWED=1 でも作者の検査は外さない"

# push 先の sha が手元に無い（fetch していない force push など）ときも、検査を素通りしない
G -c user.email=real@example.com commit -q --amend -m "add a" --author "Real Name <real@example.com>"; review
sha=$(G rev-parse HEAD)
if printf 'refs/heads/main %s refs/heads/main 1111111111111111111111111111111111111111\n' "$sha" \
    | (cd "$T/r" && bash git-hooks/pre-push) >/dev/null 2>&1; then got=pass; else got=fail; fi
check fail "$got" "pre-push: push 先の sha が手元に無くても作者を検査する"

# 注釈付きタグの tagger も noreply でなければ止める
G commit -q --amend -m "add a" --author "$NOREPLY"
G -c user.email=real@example.com tag -a v1 -m "release"
tsha=$(G rev-parse v1); mkdir -p "$T/r/.git/publish-review"; echo "要点: 確認済み" > "$T/r/.git/publish-review/$tsha"
if printf 'refs/tags/v1 %s refs/tags/v1 0000000000000000000000000000000000000000\n' "$tsha" \
    | (cd "$T/r" && bash git-hooks/pre-push) >/dev/null 2>&1; then got=pass; else got=fail; fi
check fail "$got" "pre-push: 注釈付きタグの tagger が noreply でなければ止める"

# tagger が ID の無い noreply でも止める
G -c user.email=x@users.noreply.github.com tag -a v2 -m "release"
tsha=$(G rev-parse v2); echo "要点: 確認済み" > "$T/r/.git/publish-review/$tsha"
if printf 'refs/tags/v2 %s refs/tags/v2 0000000000000000000000000000000000000000\n' "$tsha" \
    | (cd "$T/r" && bash git-hooks/pre-push) >/dev/null 2>&1; then got=pass; else got=fail; fi
check fail "$got" "pre-push: 注釈付きタグの tagger が ID の無い noreply なら止める"

# PUBLISH_REVIEWED は 1 のときだけ記録を省く
G commit -q --amend -m "add a" --author "$NOREPLY"
check fail "$(pp PUBLISH_REVIEWED=0)" "pre-push: PUBLISH_REVIEWED=0 では記録なしなら止める"
check fail "$(pp PUBLISH_REVIEWED=yes)" "pre-push: PUBLISH_REVIEWED=yes では記録なしなら止める"

# author・committer は <ID>+<名前>@users.noreply.github.com の形に限る
G commit -q --amend -m "add a" --author "tester <x@users.noreply.github.com>"; review
check fail "$(pp)" "pre-push: ID の無い noreply の author は止める"
G -c user.email=x@users.noreply.github.com commit -q --amend -m "add a" --author "$NOREPLY"; review
check fail "$(pp)" "pre-push: ID の無い noreply の committer は止める"

# worktree から push しても、メインの .git/publish-review の記録を見つける
G commit -q --amend -m "add a" --author "$NOREPLY"
G worktree add -q --detach "$T/wt" HEAD
echo "wt" > "$T/wt/b.md"; git -C "$T/wt" add b.md; git -C "$T/wt" commit -q -m "add b"
wsha=$(git -C "$T/wt" rev-parse HEAD)
echo "要点: 確認済み" > "$T/r/.git/publish-review/$wsha"
if printf 'refs/heads/main %s refs/heads/main 0000000000000000000000000000000000000000\n' "$wsha" \
    | (cd "$T/wt" && bash "$T/r/git-hooks/pre-push") >/dev/null 2>&1; then got=pass; else got=fail; fi
check pass "$got" "pre-push: worktree からでもメインの .git の記録で通す"
rm -rf "$T"
exit $fail
