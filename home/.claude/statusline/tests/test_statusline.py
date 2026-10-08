"""Tests for statusline.py. Run: python3 -m unittest discover -s <statusline>/tests"""

import json
import os
import re
import subprocess
import sys
import tempfile
import time
import unittest

HERE = os.path.dirname(os.path.abspath(__file__))
SCRIPT = os.path.join(os.path.dirname(HERE), "statusline.py")
sys.path.insert(0, os.path.dirname(HERE))
import statusline  # noqa: E402

ANSI = re.compile(r"\x1b\[[0-9;]*m|\x1b\]8;;[^\x07]*\x07")


def lines(text):
    """Visible rows, without colour codes or the blank spacer rows."""
    return [r for r in ANSI.sub("", text).split("\n") if r.strip().strip(statusline.SPACER)]


def full_input(cwd):
    now = time.time()
    return {
        "session_id": "abcdef12-3456-7890-abcd-ef1234567890",
        "session_name": "status line work",
        "model": {"id": "claude-opus-5-5", "display_name": "Opus 5.5"},
        "workspace": {"current_dir": cwd},
        "cost": {"total_cost_usd": 2.5, "total_duration_ms": 3_900_000,
                 "total_lines_added": 12, "total_lines_removed": 3},
        "context_window": {"used_percentage": 42.4, "total_input_tokens": 84_321,
                           "context_window_size": 200_000},
        "effort": {"level": "high"},
        "thinking": {"enabled": True},
        "rate_limits": {
            "five_hour": {"used_percentage": 23.5, "resets_at": now + 2 * 3600 + 14 * 60 + 30},
            "seven_day": {"used_percentage": 91, "resets_at": now + 3 * 86400 + 4 * 3600 + 60},
        },
        "worktree": {"name": "feature-x"},
        "pr": {"number": 12, "url": "https://github.com/o/r/pull/12"},
    }


class Env:
    """Isolated HOME / XDG dirs so tests never touch the real prefs or cache."""

    def __init__(self):
        self.tmp = tempfile.TemporaryDirectory(dir=os.environ.get("TMPDIR"))
        self.home = self.tmp.name
        self.project = os.path.join(self.home, "code", "app")
        os.makedirs(self.project)
        self.env = dict(os.environ, HOME=self.home,
                        XDG_CONFIG_HOME=os.path.join(self.home, "cfg"),
                        XDG_CACHE_HOME=os.path.join(self.home, "cache"))
        for key in ("STATUSLINE_EMOJI", "STATUSLINE_COMPACT", "STATUSLINE_BARS",
                    "NO_COLOR", "COLUMNS", "CLAUDE_CONFIG_DIR"):
            self.env.pop(key, None)

    def render(self, data, raw=None, **env):
        return subprocess.run([sys.executable, SCRIPT],
                              input=raw if raw is not None else json.dumps(data),
                              capture_output=True, text=True, timeout=10,
                              env=dict(self.env, **env))

    def cli(self, *args):
        return subprocess.run([sys.executable, SCRIPT, *args], capture_output=True,
                              text=True, timeout=10, env=self.env, stdin=subprocess.DEVNULL)

    def account(self, **fields):
        with open(os.path.join(self.home, ".claude.json"), "w") as f:
            json.dump({"oauthAccount": fields}, f)

    def prefs_file(self):
        return os.path.join(self.env["XDG_CONFIG_HOME"], "claude-statusline", "prefs.json")

    def close(self):
        self.tmp.cleanup()


class RenderTests(unittest.TestCase):
    def setUp(self):
        self.e = Env()
        self.addCleanup(self.e.close)

    def rows(self, data=None, **env):
        proc = self.e.render(full_input(self.e.project) if data is None else data, **env)
        self.assertEqual(proc.returncode, 0, proc.stderr)
        self.assertEqual(proc.stderr, "")
        return lines(proc.stdout)

    def test_default_layout(self):
        rows = self.rows()
        self.assertEqual(len(rows), 2, rows)  # header + gauges; session row is opt-in
        self.assertTrue(rows[0].startswith("📁 ~/code/app"), rows[0])
        self.assertIn("🌿 none", rows[0])  # not a git repo
        self.assertIn("🌳 feature-x", rows[0])
        self.assertIn("PR #12", rows[0])
        self.assertIn("🧠 Opus 5.5", rows[0])
        self.assertIn("⚡ high", rows[0])
        self.assertNotIn("think", rows[0])
        self.assertIn("ctx", rows[1])
        self.assertIn("42%", rows[1])
        self.assertNotIn("84k", rows[1])
        self.assertIn("24%", rows[1])  # 23.5 rounds half-to-even → 24
        self.assertIn("↻2h14m", rows[1])
        self.assertIn("7d", rows[1])
        self.assertIn("↻3d4h", rows[1])

    def test_rows_are_spaced(self):
        out = self.e.render(full_input(self.e.project)).stdout
        self.assertIn("\n%s\n" % statusline.SPACER, out)
        self.assertTrue(out.endswith("\n%s\n" % statusline.SPACER), repr(out[-20:]))  # gap above the footer
        self.assertNotIn("\n \n", out)  # whitespace-only rows get dropped by Claude Code

    def test_80_column_pane_one_header_row_and_keeps_weekly(self):
        rows = self.rows(COLUMNS="80")
        self.assertEqual(len(rows), 2, rows)
        self.assertTrue(rows[0].startswith("📁 ~/code/app"))
        self.assertIn("  │  🧠 Opus 5.5", rows[0])
        self.assertTrue(rows[0].endswith("⚡ high"), rows[0])
        self.assertNotIn("   ", rows[0].replace("  │  ", ""))  # no padding gaps
        self.assertIn("7d", rows[1])
        self.assertIn("↻3d4h", rows[1])
        for row in rows:
            self.assertLessEqual(statusline.vwidth(row), 76, row)

    def test_narrow_pane_splits_header_and_drops_weekly_first(self):
        rows = self.rows(COLUMNS="54")
        for row in rows:
            self.assertLessEqual(statusline.vwidth(row), 50, row)
        self.assertTrue(rows[0].startswith("📁 ~/code/app"))
        self.assertTrue(any(r.startswith("🧠 Opus 5.5") for r in rows), rows)
        self.assertIn("ctx", rows[-1])
        self.assertIn("5h", rows[-1])
        self.assertNotIn("7d", rows[-1])

    def test_session_row_is_opt_in(self):
        self.e.cli("show", "sid", "name", "duration", "lines")
        rows = self.rows()
        self.assertEqual(len(rows), 3)
        self.assertIn("sid abcdef12", rows[2])
        self.assertIn("status line work", rows[2])
        self.assertIn("1h05m", rows[2])
        self.assertIn("+12 −3", rows[2])
        self.assertNotIn("$", rows[2])  # cost still hidden

    def test_no_worktree_shows_none(self):
        data = full_input(self.e.project)
        del data["worktree"]
        self.assertIn("🌳 none", self.rows(data)[0])

    def test_colours_follow_thresholds(self):
        out = self.e.render(full_input(self.e.project)).stdout
        self.assertIn("\x1b[31m91%", out)   # 7d at 91 → red
        self.assertIn("\x1b[32m42%", out)   # ctx at 42 → green
        self.assertIn("\x1b]8;;https://github.com/o/r/pull/12\x07", out)

    def test_no_color(self):
        out = self.e.render(full_input(self.e.project), NO_COLOR="1").stdout
        self.assertNotIn("\x1b", out)

    def test_minimal_and_nulls_never_print_none(self):
        data = {"model": {"display_name": "Opus"}, "workspace": {"current_dir": "/nonexistent/x"},
                "context_window": {"used_percentage": None}, "rate_limits": None,
                "effort": None, "cost": {"total_duration_ms": None}}
        out = "\n".join(self.rows(data))
        self.assertNotIn("None", out)
        self.assertIn("ctx —", out)
        self.assertNotIn("5h", out)

    def test_garbage_and_empty_stdin(self):
        for raw in ("not json", "", "[1,2]", '"str"', '{"model": 5, "workspace": []}'):
            proc = self.e.render(None, raw=raw)
            self.assertEqual(proc.returncode, 0, proc.stderr)
            self.assertTrue(lines(proc.stdout), "blank for %r" % raw)
            self.assertNotIn("Traceback", proc.stdout + proc.stderr)

    def test_no_rate_limits_shows_ctx_only(self):
        data = full_input(self.e.project)
        del data["rate_limits"]
        rows = self.rows(data)
        self.assertIn("ctx", rows[-1])
        self.assertNotIn("7d", rows[-1])

    def test_git_branch_and_dirty(self):
        repo = os.path.join(self.e.home, "repo")
        os.makedirs(repo)
        git = ["git", "-C", repo, "-c", "user.name=t", "-c", "user.email=t@t"]
        subprocess.run(git + ["init", "-q", "-b", "trunk"], check=True, env=self.e.env)
        subprocess.run(git + ["commit", "-q", "--allow-empty", "-m", "x"], check=True, env=self.e.env)
        clean = self.rows(full_input(repo))[0]
        self.assertIn("🌿 trunk", clean)
        self.assertNotIn("trunk*", clean)
        with open(os.path.join(repo, "f"), "w") as f:
            f.write("x")
        # git info is cached for a few seconds; a new cache dir forces a re-read
        dirty = self.rows(full_input(repo), XDG_CACHE_HOME=os.path.join(self.e.home, "c2"))[0]
        self.assertIn("🌿 trunk*", dirty)

    def test_tier_from_account(self):
        self.e.account(organizationType="claude_max", userRateLimitTier="default_claude_max_20x")
        self.assertIn("Max 20x", self.rows()[0])
        self.e.account(organizationType="claude_pro", organizationRateLimitTier="default_claude_ai")
        self.assertIn("Pro", self.rows()[0])

    def test_tier_missing_or_odd_account(self):
        self.assertNotIn("Pro", self.rows()[0])  # no ~/.claude.json
        with open(os.path.join(self.e.home, ".claude.json"), "w") as f:
            f.write('{"oauthAccount": "weird"}')
        self.rows()

    def test_saves_last_input_for_preview(self):
        self.e.render(full_input(self.e.project))
        path = os.path.join(self.e.env["XDG_CACHE_HOME"], "claude-statusline", "last.json")
        with open(path) as f:
            self.assertEqual(json.load(f)["session_name"], "status line work")


class PrefsTests(unittest.TestCase):
    def setUp(self):
        self.e = Env()
        self.addCleanup(self.e.close)

    def rows(self, **env):
        proc = self.e.render(full_input(self.e.project), **env)
        self.assertEqual(proc.returncode, 0, proc.stderr)
        return lines(proc.stdout)

    def test_emoji_toggle_applies_without_restart(self):
        rows = self.rows()
        self.assertIn("🧠 Opus 5.5", rows[0])  # folder/model/effort always carry emoji
        self.assertNotIn("⏳", rows[1])
        self.assertIn("emoji on", self.e.cli("emoji").stdout)
        rows = self.rows()
        self.assertIn("⏳ 5h", rows[1])
        self.assertIn("📊", rows[1])
        self.assertIn("emoji off", self.e.cli("emoji", "off").stdout)
        self.assertNotIn("⏳", "\n".join(self.rows()))

    def test_env_overrides_prefs(self):
        self.e.cli("emoji", "on")
        self.assertNotIn("⏳", "\n".join(self.rows(STATUSLINE_EMOJI="0")))
        self.assertIn("⏳", "\n".join(self.rows(STATUSLINE_EMOJI="1")))

    def test_compact_is_one_row(self):
        self.e.cli("compact", "on")
        rows = self.rows()
        self.assertEqual(len(rows), 1, rows)
        self.assertIn("Opus 5.5", rows[0])
        self.assertIn("ctx 42%", rows[0])
        self.assertIn("7d 91%", rows[0])
        self.assertNotIn("sid", rows[0])

    def test_hide_and_show(self):
        self.e.account(organizationType="claude_pro")
        self.assertIn("Pro", self.rows()[0])
        self.e.cli("hide", "tier")
        self.e.cli("show", "cost", "sid", "thinking")
        rows = self.rows()
        self.assertNotIn("Pro", rows[0])
        self.assertIn("thinking", rows[0])
        self.assertIn("sid", rows[2])
        self.assertIn("~$2.50", rows[2])
        self.assertNotIn("status line work", rows[2])
        with open(self.e.prefs_file()) as f:
            saved = json.load(f)
        self.assertEqual(saved["hide"], ["tier"])
        self.assertEqual(saved["show"], ["cost", "sid", "thinking"])
        self.e.cli("hide", "sid", "cost", "thinking")  # back to the defaults
        self.assertEqual(len(self.rows()), 2)

    def test_old_prefs_do_not_pin_old_defaults(self):
        os.makedirs(os.path.dirname(self.e.prefs_file()))
        with open(self.e.prefs_file(), "w") as f:
            json.dump({"emoji": False, "compact": False, "hide": ["cost"]}, f)
        self.assertEqual(len(self.rows()), 2)  # session row stays hidden

    def test_bar_styles(self):
        self.assertIn("█", self.rows()[1])  # block is the default
        self.assertIn("bars pill", self.e.cli("bars", "pill").stdout)
        row = self.rows()[1]
        self.assertIn("▰", row)
        self.assertNotIn("█", row)
        self.assertIn("●", self.rows(STATUSLINE_BARS="dots")[1])
        self.assertIn("bars:    pill", self.e.cli("status").stdout)

    def test_bad_cli_args(self):
        self.assertEqual(self.e.cli("bars", "chunky").returncode, 2)
        self.assertEqual(self.e.cli("bars").returncode, 2)
        self.assertEqual(self.e.cli("hide", "nope").returncode, 2)
        self.assertEqual(self.e.cli("emoji", "maybe").returncode, 2)
        self.assertEqual(self.e.cli("frobnicate").returncode, 2)

    def test_unwritable_prefs_is_a_clean_error(self):
        blocker = os.path.join(self.e.home, "blocker")
        open(blocker, "w").close()  # a file where the config dir should go
        self.e.env["XDG_CONFIG_HOME"] = blocker
        proc = self.e.cli("emoji", "on")
        self.assertEqual(proc.returncode, 1)
        self.assertIn("cannot write", proc.stderr)
        self.assertNotIn("Traceback", proc.stderr)

    def test_corrupt_prefs_fall_back_to_defaults(self):
        os.makedirs(os.path.dirname(self.e.prefs_file()))
        with open(self.e.prefs_file(), "w") as f:
            f.write("{oops")
        self.assertEqual(len(self.rows()), 2)

    def test_preview_and_status_without_history(self):
        out = self.e.cli("preview")
        self.assertEqual(out.returncode, 0, out.stderr)
        self.assertIn("sample input", out.stdout)
        for name in ("text", "emoji", "compact", "compact + emoji", "bars"):
            self.assertIn("── %s ──" % name, out.stdout)
        for style in ("block", "pill", "dots", "line"):
            self.assertRegex(out.stdout, r"\n%-6s ctx " % style)
        # bare `statusline` only shows status on a tty; without one it renders
        status = self.e.cli("status")
        self.assertIn("emoji:   off", status.stdout)


class FormatTests(unittest.TestCase):
    def test_countdown(self):
        self.assertEqual(statusline.countdown(-5), "now")
        self.assertEqual(statusline.countdown(30), "1m")
        self.assertEqual(statusline.countdown(42 * 60), "42m")
        self.assertEqual(statusline.countdown(2 * 3600 + 5 * 60), "2h05m")
        self.assertEqual(statusline.countdown(3 * 86400 + 4 * 3600), "3d4h")

    def test_display_path_and_width(self):
        home = "/Users/me"
        self.assertEqual(statusline.display_path("/Users/me/developer/app", home), "~/developer/app")
        self.assertEqual(statusline.display_path("/Users/me/developer/app/", home), "~/developer/app")
        self.assertEqual(statusline.display_path("/Users/me", home), "~")
        self.assertEqual(statusline.display_path("/Users/meow/x", home), "/Users/meow/x")
        self.assertEqual(statusline.display_path("/", home), "/")
        self.assertEqual(statusline.vwidth("\x1b[31mab\x1b[0m"), 2)
        self.assertEqual(statusline.vwidth("🧠x"), 3)

    def test_parse_git_status(self):
        info = statusline.parse_git_status(
            "# branch.oid abc\n# branch.head main\n# branch.ab +2 -1\n? new\n")
        self.assertEqual(info, {"branch": "main", "ahead": 2, "behind": 1, "dirty": True})
        self.assertIsNone(statusline.parse_git_status("# branch.head (detached)\n")["branch"])


if __name__ == "__main__":
    unittest.main()
