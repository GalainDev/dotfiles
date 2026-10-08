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
        self.env = dict(os.environ, HOME=self.home,
                        XDG_CONFIG_HOME=os.path.join(self.home, "cfg"),
                        XDG_CACHE_HOME=os.path.join(self.home, "cache"))
        for key in ("STATUSLINE_EMOJI", "STATUSLINE_COMPACT", "NO_COLOR", "COLUMNS",
                    "CLAUDE_CONFIG_DIR"):
            self.env.pop(key, None)

    def render(self, data, raw=None, **env):
        proc = subprocess.run([sys.executable, SCRIPT],
                              input=raw if raw is not None else json.dumps(data),
                              capture_output=True, text=True, timeout=10,
                              env=dict(self.env, **env))
        return proc

    def cli(self, *args):
        return subprocess.run([sys.executable, SCRIPT, *args], capture_output=True,
                              text=True, timeout=10, env=self.env, stdin=subprocess.DEVNULL)

    def account(self, **fields):
        with open(os.path.join(self.home, ".claude.json"), "w") as f:
            json.dump({"oauthAccount": fields}, f)

    def close(self):
        self.tmp.cleanup()


class RenderTests(unittest.TestCase):
    def setUp(self):
        self.e = Env()
        self.addCleanup(self.e.close)

    def plain(self, proc):
        self.assertEqual(proc.returncode, 0, proc.stderr)
        self.assertEqual(proc.stderr, "")
        return ANSI.sub("", proc.stdout)

    def test_full_input_three_rows(self):
        out = self.plain(self.e.render(full_input(self.e.home)))
        rows = out.rstrip("\n").split("\n")
        self.assertEqual(len(rows), 3, out)
        self.assertIn("~", rows[0])
        self.assertIn("wt feature-x", rows[0])
        self.assertIn("PR #12", rows[0])
        self.assertIn("Opus 5.5", rows[0])
        self.assertIn("effort high", rows[0])
        self.assertIn("think", rows[0])
        self.assertIn("42%", rows[1])
        self.assertIn("84k/200k", rows[1])
        self.assertIn("5h", rows[1])
        self.assertIn("24%", rows[1])  # 23.5 rounds half-to-even → 24
        self.assertIn("↻2h14m", rows[1])
        self.assertIn("↻3d4h", rows[1])
        self.assertIn("sid abcdef12", rows[2])
        self.assertIn("status line work", rows[2])
        self.assertIn("1h05m", rows[2])
        self.assertIn("+12 −3", rows[2])
        self.assertNotIn("$", rows[2])  # cost hidden by default

    def test_colours_follow_thresholds(self):
        out = self.e.render(full_input(self.e.home)).stdout
        self.assertIn("\x1b[31m91%", out)   # 7d at 91 → red
        self.assertIn("\x1b[32m42%", out)   # ctx at 42 → green
        self.assertIn("\x1b]8;;https://github.com/o/r/pull/12\x07", out)

    def test_no_color(self):
        out = self.e.render(full_input(self.e.home), NO_COLOR="1").stdout
        self.assertNotIn("\x1b", out)

    def test_minimal_and_nulls_never_print_none(self):
        data = {"model": {"display_name": "Opus"}, "workspace": {"current_dir": "/nonexistent/x"},
                "context_window": {"used_percentage": None}, "rate_limits": None,
                "effort": None, "cost": {"total_duration_ms": None}}
        out = self.plain(self.e.render(data))
        self.assertNotIn("None", out)
        self.assertIn("ctx —", out)
        self.assertNotIn("5h", out)

    def test_garbage_and_empty_stdin(self):
        for raw in ("not json", "", "[1,2]", '"str"', '{"model": 5, "workspace": []}'):
            out = self.plain(self.e.render(None, raw=raw))
            self.assertTrue(out.strip(), "blank for %r" % raw)
            self.assertNotIn("Traceback", out)

    def test_no_rate_limits_shows_ctx_only(self):
        data = full_input(self.e.home)
        del data["rate_limits"]
        rows = self.plain(self.e.render(data)).split("\n")
        self.assertIn("ctx", rows[1])
        self.assertNotIn("7d", rows[1])

    def test_narrow_terminal_drops_low_priority_segments(self):
        out = self.plain(self.e.render(full_input(self.e.home), COLUMNS="54"))
        for row in out.rstrip("\n").split("\n"):
            self.assertLessEqual(statusline.vwidth(row), 50, row)
        self.assertIn("Opus 5.5", out)
        self.assertIn("ctx", out)
        self.assertNotIn("PR #12", out)

    def test_git_branch_and_dirty(self):
        repo = os.path.join(self.e.home, "repo")
        os.makedirs(repo)
        git = ["git", "-C", repo, "-c", "user.name=t", "-c", "user.email=t@t"]
        subprocess.run(git + ["init", "-q", "-b", "trunk"], check=True, env=self.e.env)
        subprocess.run(git + ["commit", "-q", "--allow-empty", "-m", "x"], check=True, env=self.e.env)
        clean = self.plain(self.e.render(full_input(repo)))
        self.assertIn("⎇ trunk", clean)
        self.assertNotIn("trunk*", clean)
        with open(os.path.join(repo, "f"), "w") as f:
            f.write("x")
        # git info is cached for a few seconds; a new cache dir forces a re-read
        dirty = self.plain(self.e.render(full_input(repo), XDG_CACHE_HOME=os.path.join(self.e.home, "c2")))
        self.assertIn("⎇ trunk*", dirty)

    def test_tier_from_account(self):
        self.e.account(organizationType="claude_max", userRateLimitTier="default_claude_max_20x")
        self.assertIn("Max 20x", self.plain(self.e.render(full_input(self.e.home))))
        self.e.account(organizationType="claude_pro", organizationRateLimitTier="default_claude_ai")
        self.assertIn("Pro", self.plain(self.e.render(full_input(self.e.home))))

    def test_tier_missing_or_odd_account(self):
        out = self.plain(self.e.render(full_input(self.e.home)))  # no ~/.claude.json
        self.assertNotIn("Pro", out)
        with open(os.path.join(self.e.home, ".claude.json"), "w") as f:
            f.write('{"oauthAccount": "weird"}')
        self.plain(self.e.render(full_input(self.e.home)))

    def test_saves_last_input_for_preview(self):
        self.e.render(full_input(self.e.home))
        path = os.path.join(self.e.env["XDG_CACHE_HOME"], "claude-statusline", "last.json")
        with open(path) as f:
            self.assertEqual(json.load(f)["session_name"], "status line work")


class PrefsTests(unittest.TestCase):
    def setUp(self):
        self.e = Env()
        self.addCleanup(self.e.close)

    def rows(self, **env):
        proc = self.e.render(full_input(self.e.home), **env)
        self.assertEqual(proc.returncode, 0, proc.stderr)
        return ANSI.sub("", proc.stdout).rstrip("\n").split("\n")

    def test_emoji_toggle_applies_without_restart(self):
        self.assertNotIn("🧠", "\n".join(self.rows()))
        self.assertIn("emoji on", self.e.cli("emoji").stdout)
        rows = self.rows()
        self.assertIn("🧠 Opus 5.5", rows[0])
        self.assertIn("⏳ 5h", rows[1])
        self.assertIn("💭", rows[0])
        self.assertIn("emoji off", self.e.cli("emoji", "off").stdout)
        self.assertNotIn("🧠", "\n".join(self.rows()))

    def test_env_overrides_prefs(self):
        self.e.cli("emoji", "on")
        self.assertNotIn("🧠", "\n".join(self.rows(STATUSLINE_EMOJI="0")))
        self.assertIn("🧠", "\n".join(self.rows(STATUSLINE_EMOJI="1")))

    def test_compact_is_one_row(self):
        self.e.cli("compact", "on")
        rows = self.rows()
        self.assertEqual(len(rows), 1, rows)
        self.assertIn("Opus 5.5", rows[0])
        self.assertIn("ctx 42%", rows[0])
        self.assertIn("7d 91%", rows[0])
        self.assertNotIn("sid", rows[0])

    def test_hide_and_show(self):
        self.e.cli("hide", "sid", "name")
        self.assertNotIn("sid", self.rows()[2])
        self.e.cli("show", "cost", "sid")
        last = self.rows()[2]
        self.assertIn("sid", last)
        self.assertIn("~$2.50", last)
        self.assertNotIn("status line work", last)

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
        os.makedirs(os.path.join(self.e.env["XDG_CONFIG_HOME"], "claude-statusline"))
        with open(os.path.join(self.e.env["XDG_CONFIG_HOME"], "claude-statusline", "prefs.json"), "w") as f:
            f.write("{oops")
        self.assertEqual(len(self.rows()), 3)

    def test_preview_and_status_without_history(self):
        out = self.e.cli("preview")
        self.assertEqual(out.returncode, 0, out.stderr)
        self.assertIn("sample input", out.stdout)
        for name in ("text", "emoji", "compact", "compact + emoji", "bars"):
            self.assertIn("── %s ──" % name, out.stdout)
        for style in ("block", "pill", "dots", "line"):
            self.assertIn("\n%-6s " % style, out.stdout)
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

    def test_tokens_and_width(self):
        self.assertEqual(statusline.tokens(999), "999")
        self.assertEqual(statusline.tokens(84_321), "84k")
        self.assertEqual(statusline.tokens(1_000_000), "1.0M")
        self.assertEqual(statusline.vwidth("\x1b[31mab\x1b[0m"), 2)
        self.assertEqual(statusline.vwidth("🧠x"), 3)

    def test_parse_git_status(self):
        info = statusline.parse_git_status(
            "# branch.oid abc\n# branch.head main\n# branch.ab +2 -1\n? new\n")
        self.assertEqual(info, {"branch": "main", "ahead": 2, "behind": 1, "dirty": True})
        self.assertIsNone(statusline.parse_git_status("# branch.head (detached)\n")["branch"])


if __name__ == "__main__":
    unittest.main()
