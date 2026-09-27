"""prompt_eval.py の決定的なテスト。偽の claude（fake_claude.py）を使い、実際の API は呼ばない。

  python3 -m unittest discover -s tests   （スキルのディレクトリで実行する）
"""
import json
import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent / "scripts"))
import prompt_eval as pe  # noqa: E402

CASE_PROMPT = """---
name: {name}
runs: 3
prompt_eval:
  kind: {kind}
  expected_difference: >
    after は md を file:// リンクで示す。
    before は裸のパス。
---
x.md はどこ？
"""
REGEX_GRADER = """---
type: regex
match: contains
---
\\]\\(file:///[^)]*\\.md\\)
"""
LLM_GRADER = """---
type: llm
focus: final
---
md ファイルを file:// の markdown リンクで示している。
"""


def git(repo, *a):
    subprocess.run(["git", "-C", str(repo), *a], check=True, capture_output=True)


class VerdictTest(unittest.TestCase):
    def test_change_rules(self):
        T, F = True, False
        self.assertEqual(pe.verdict_for("change", 3, [F, F, F], [T, T, F])[0], "pass")
        self.assertEqual(pe.verdict_for("change", 3, [T, F, F], [T, T, T])[0], "pass")
        self.assertEqual(pe.verdict_for("change", 3, [T, T, F], [T, T, T])[0], "not-discriminating")
        self.assertEqual(pe.verdict_for("change", 3, [F, F, F], [T, F, F])[0], "fail")
        self.assertEqual(pe.verdict_for("change", 3, [F, None, F], [T, T, T])[0], "inconclusive")

    def test_regression_rules(self):
        T, F = True, False
        self.assertEqual(pe.verdict_for("regression", 3, [], [T, T, F])[0], "pass")
        self.assertEqual(pe.verdict_for("regression", 3, [], [T, F, F])[0], "inconclusive")
        self.assertEqual(pe.verdict_for("regression", 3, [T, T, T], [T, F, F])[0], "fail")
        self.assertEqual(pe.verdict_for("regression", 3, [T, F, F], [T, F, F])[0], "unstable")
        self.assertEqual(pe.verdict_for("regression", 3, [], [T, None, T])[0], "inconclusive")

    def test_calibration(self):
        T, F = True, False
        self.assertEqual(pe.calibration_for(3, [T, T, F], [T, T, T])["status"], "consistent")
        self.assertEqual(pe.calibration_for(3, [T, T, T], [F, F, T])["status"], "inconsistent")

    def test_frontmatter(self):
        meta, body = pe.parse_frontmatter(CASE_PROMPT.format(name="a", kind="change"))
        self.assertEqual(meta["runs"], 3)
        self.assertEqual(meta["prompt_eval"]["kind"], "change")
        self.assertIn("before は裸のパス。", meta["prompt_eval"]["expected_difference"])
        self.assertEqual(body.strip(), "x.md はどこ？")
        meta, _ = pe.parse_frontmatter("---\nallowed_tools: [Read, Bash]\ncwd: ~/x  # c\n---\nq")
        self.assertEqual(meta["allowed_tools"], ["Read", "Bash"])
        self.assertEqual(meta["cwd"], "~/x")

    def test_render_global_expands_import_and_overrides_target(self):
        with tempfile.TemporaryDirectory() as d:
            d = Path(d)
            (d / "part.md").write_text("PART-WORKTREE")
            (d / "CLAUDE.md").write_text("head\n@part.md\ntail")
            out = pe.render_global(d / "CLAUDE.md", {(d / "part.md").resolve(): "PART-BEFORE"})
            self.assertEqual(out, "head\nPART-BEFORE\ntail")


class EndToEndTest(unittest.TestCase):
    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp())
        os.environ["PROMPT_EVAL_CLAUDE_BIN"] = f"{sys.executable} {HERE / 'fake_claude.py'}"
        os.environ["CLAUDECODE"] = "1"  # ランナーが外すことを確かめる
        for k in ("FAKE_FLAKY", "FAKE_USAGE_LIMIT", "FAKE_COUNTER", "FAKE_JUDGE_FLAKY", "FAKE_GLOBAL_MD"):
            os.environ.pop(k, None)

    def make_cases(self, kind="change", graders=(("link", REGEX_GRADER),)):
        cases = self.tmp / "cases"
        c = cases / "md-link"
        (c / "graders").mkdir(parents=True)
        (c / "prompt.md").write_text(CASE_PROMPT.format(name="md-link", kind=kind))
        for name, body in graders:
            (c / "graders" / f"{name}.md").write_text(body)
        return cases

    def make_repo(self, name, head="# rules\n", work="# rules\nRULE_LINK\n"):
        repo = self.tmp / name
        repo.mkdir()
        git(repo, "init", "-q")
        git(repo, "config", "user.email", "t@example.com")
        git(repo, "config", "user.name", "t")
        (repo / "CLAUDE.md").write_text(head)
        git(repo, "add", ".")
        git(repo, "commit", "-qm", "init")
        (repo / "CLAUDE.md").write_text(work)
        return repo

    def run_pe(self, *extra):
        out = self.tmp / "out"
        rc = pe.main(["run", *extra, "--cases", str(self.tmp / "cases"), "--out", str(out), "--jobs", "1"])
        rec = json.loads(next(out.glob("*/record.json")).read_text())
        return rc, rec

    def test_global_mode_change_passes(self):
        self.make_cases(graders=(("link", REGEX_GRADER), ("link-llm", LLM_GRADER)))
        home = self.make_repo("dotclaude")
        rc, rec = self.run_pe("--mode", "global", "--file", str(home / "CLAUDE.md"),
                              "--global-md", str(home / "CLAUDE.md"))
        case = rec["cases"][0]
        self.assertEqual(rc, 0, rec)
        self.assertEqual(case["arms"]["before"]["passed"], 0)
        self.assertEqual(case["arms"]["after"]["passed"], 3)
        self.assertTrue(all(g["discriminating"] for g in case["graders"]))
        self.assertNotEqual(rec["versions"]["before"], rec["versions"]["after"])

    def test_repo_mode_uses_worktrees_and_cleans_up(self):
        self.make_cases()
        repo = self.make_repo("proj")
        rc, rec = self.run_pe("--mode", "repo", "--file", str(repo / "CLAUDE.md"))
        self.assertEqual(rc, 0, rec)
        self.assertEqual(rec["cases"][0]["verdict"], "pass")
        wt = subprocess.run(["git", "-C", str(repo), "worktree", "list"], capture_output=True, text=True).stdout
        self.assertEqual(len(wt.strip().splitlines()), 1, wt)
        # 作業ツリーの after は触らない
        self.assertIn("RULE_LINK", (repo / "CLAUDE.md").read_text())

    def test_no_change_is_not_discriminating(self):
        self.make_cases()
        repo = self.make_repo("proj")
        rc, rec = self.run_pe("--mode", "repo", "--file", str(repo / "CLAUDE.md"),
                              "--before-ref", "worktree")
        self.assertEqual(rc, 1)
        self.assertEqual(rec["cases"][0]["verdict"], "not-discriminating")
        self.assertEqual(rec["cases"][0]["graders"][0]["warning"], "always-pass-both")

    def test_usage_limit_is_inconclusive_not_fail(self):
        self.make_cases()
        repo = self.make_repo("proj")
        os.environ["FAKE_USAGE_LIMIT"] = "1"
        rc, rec = self.run_pe("--mode", "repo", "--file", str(repo / "CLAUDE.md"))
        self.assertEqual(rc, 1)
        self.assertEqual(rec["cases"][0]["verdict"], "inconclusive")
        self.assertEqual(rec["result"]["verdict"], "inconclusive")

    def test_budget_stops_runs(self):
        self.make_cases()
        repo = self.make_repo("proj")
        rc, rec = self.run_pe("--mode", "repo", "--file", str(repo / "CLAUDE.md"), "--max-cost", "0.015")
        self.assertTrue(rec["result"]["partial"])
        self.assertEqual(rec["result"]["verdict"], "inconclusive")

    def test_judge_retries_invalid_vote(self):
        self.make_cases(graders=(("link-llm", LLM_GRADER),))
        repo = self.make_repo("proj")
        os.environ["FAKE_JUDGE_FLAKY"] = str(self.tmp / "judge-flaky")
        rc, rec = self.run_pe("--mode", "repo", "--file", str(repo / "CLAUDE.md"))
        self.assertEqual(rc, 0, rec)
        raws = list((self.tmp / "out").glob("*/runs/md-link/*/*/judge/*.json"))
        self.assertEqual(len(raws), 7)  # 6 実行 × 1 票 ＋ 引き直し 1 回

    def test_regression_runs_after_only_when_it_passes(self):
        self.make_cases(kind="regression")
        repo = self.make_repo("proj", head="# rules\nRULE_LINK\n", work="# rules\nRULE_LINK\nother\n")
        rc, rec = self.run_pe("--mode", "repo", "--file", str(repo / "CLAUDE.md"))
        self.assertEqual(rc, 0, rec)
        self.assertEqual(rec["cases"][0]["arms"]["before"]["ran"], 0)
        self.assertFalse(list((self.tmp / "out").glob("*/runs/md-link/before")))

    def test_regression_failure_runs_before_and_reports_regression(self):
        self.make_cases(kind="regression")
        repo = self.make_repo("proj", head="# rules\nRULE_LINK\n", work="# rules\n")
        rc, rec = self.run_pe("--mode", "repo", "--file", str(repo / "CLAUDE.md"))
        self.assertEqual(rc, 1)
        case = rec["cases"][0]
        self.assertEqual(case["verdict"], "fail")
        self.assertEqual(case["arms"]["before"]["passed"], 3)
        self.assertNotIn("warning", case["graders"][0])

    def test_calibrate_compares_native_loading(self):
        self.make_cases()
        home = self.make_repo("dotclaude")
        os.environ["FAKE_GLOBAL_MD"] = str(home / "CLAUDE.md")
        rc, rec = self.run_pe("--mode", "global", "--file", str(home / "CLAUDE.md"),
                              "--global-md", str(home / "CLAUDE.md"), "--calibrate")
        self.assertEqual(rc, 0, rec)
        self.assertTrue(rec["provisional"])
        self.assertEqual(rec["cases"][0]["calibration"]["status"], "consistent")


if __name__ == "__main__":
    unittest.main()
