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
rm -rf "$T"
exit $fail
