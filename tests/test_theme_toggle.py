#!/usr/bin/env python3
"""Exercise theme-toggle against disposable configs, never the operator's HOME."""

import json
import os
from pathlib import Path
import shlex
import stat
import subprocess
import sys
import tempfile
import tomllib
import unittest


SCRIPT = Path(__file__).resolve().parents[1] / "scripts/.local/bin/theme-toggle"


class ThemeToggleTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory(prefix="theme-toggle-test-")
        self.addCleanup(temporary.cleanup)
        self.home = Path(temporary.name)
        self.shims = self.home / "bin"
        self.shims.mkdir()
        self.env = dict(os.environ, HOME=str(self.home))
        self.env["PATH"] = str(self.shims) + os.pathsep + os.environ["PATH"]
        self.configs = {
            "claude": (self.home / ".claude/settings.json", 0o640),
            "codex": (self.home / ".codex/config.toml", 0o600),
            "grok": (self.home / ".grok/config.toml", 0o644),
        }
        fixtures = {
            "claude": '{"theme":"light","unrelated":{"keep":true}}\n',
            "codex": (
                'model = "example"\n[tui]\ntheme = "catppuccin-latte"\n'
                '[tui.keymap.global]\nopen_transcript = "ctrl-t"\n'
            ),
            "grok": (
                '[ui]\ntheme = "grokday"\ncompact_mode = false\n'
                '[ui.status_line]\ncommand = "keep-me"\n'
            ),
        }
        for name, (path, mode) in self.configs.items():
            path.parent.mkdir(parents=True)
            path.write_text(fixtures[name])
            path.chmod(mode)
        alacritty = self.home / ".config/alacritty/alacritty.toml"
        alacritty.parent.mkdir(parents=True)
        alacritty.write_text(
            'general.import = [\n  "~/.config/alacritty/catppuccin-latte.toml"\n'
            '  # "~/.config/alacritty/catppuccin-macchiato.toml"\n]\n'
        )
        zellij = self.home / ".config/zellij/config.kdl"
        zellij.parent.mkdir(parents=True)
        zellij.write_text('theme "catppuccin-latte"\n')

    def run_toggle(self, mode):
        return subprocess.run(
            ["bash", str(SCRIPT), mode], env=self.env,
            text=True, capture_output=True, check=False,
        )

    def shim(self, command, body):
        path = self.shims / command
        path.write_text("#!/usr/bin/env bash\n" + body)
        path.chmod(0o755)

    def settings(self, name):
        path = self.configs[name][0]
        if name == "claude":
            return json.loads(path.read_text())
        return tomllib.loads(path.read_text())

    def assert_permissions_preserved(self):
        for name, (path, mode) in self.configs.items():
            self.assertEqual(stat.S_IMODE(path.stat().st_mode), mode, name)
        self.assertEqual(list(self.home.rglob(".theme-toggle.*")), [])

    def test_dark_preserves_permissions_and_unrelated_settings(self):
        result = self.run_toggle("dark")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stderr, "")
        self.assertEqual(self.settings("claude"), {"theme": "dark", "unrelated": {"keep": True}})
        self.assertEqual(self.settings("codex")["tui"]["theme"], "catppuccin-macchiato")
        self.assertEqual(self.settings("codex")["tui"]["keymap"]["global"]["open_transcript"], "ctrl-t")
        self.assertEqual(self.settings("grok")["ui"]["theme"], "groknight")
        self.assertEqual(self.settings("grok")["ui"]["status_line"]["command"], "keep-me")
        self.assert_permissions_preserved()

    def test_bsd_stat_fallback_discards_failed_probe_stdout(self):
        self.shim("stat", (
            'if [[ "$1" == -c ]]; then echo "failed probe output"; exit 1; fi\n'
            '[[ "$1" == -f && "$2" == %Lp ]] || exit 1\n'
            f'exec {shlex.quote(sys.executable)} -c '
            "'import os,stat,sys; print(format(stat.S_IMODE(os.stat(sys.argv[1]).st_mode), \"o\"))' "
            '"$3"\n'
        ))
        result = self.run_toggle("dark")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stderr, "")
        self.assert_permissions_preserved()

    def test_write_failures_preserve_configs_and_report_failure(self):
        for command in ("stat", "chmod", "mv"):
            with self.subTest(command=command):
                before = {name: path.read_bytes() for name, (path, _) in self.configs.items()}
                self.shim(command, f'echo "injected {command} failure" >&2\nexit 1\n')
                result = self.run_toggle("dark")
                self.assertNotEqual(result.returncode, 0, result.stdout)
                self.assertNotIn("restart to pick it up", result.stdout)
                for name, (path, _) in self.configs.items():
                    self.assertEqual(path.read_bytes(), before[name], name)
                    self.assertNotIn(f"  {name}:", result.stdout)
                self.assert_permissions_preserved()
                (self.shims / command).unlink()

    def test_one_invalid_config_does_not_hide_failure_behind_later_success(self):
        path = self.configs["claude"][0]
        path.write_text("invalid json\n")
        result = self.run_toggle("dark")
        self.assertNotEqual(result.returncode, 0, result.stdout)
        self.assertEqual(path.read_text(), "invalid json\n")
        self.assertNotIn("  claude:", result.stdout)
        self.assertIn("  codex:", result.stdout)
        self.assertIn("  grok:", result.stdout)
        self.assert_permissions_preserved()

    def test_invalid_toml_is_left_untouched(self):
        path = self.configs["codex"][0]
        path.write_text("invalid toml [\n")
        result = self.run_toggle("dark")
        self.assertNotEqual(result.returncode, 0, result.stdout)
        self.assertEqual(path.read_text(), "invalid toml [\n")
        self.assertNotIn("  codex:", result.stdout)
        self.assert_permissions_preserved()

    def test_symlink_and_target_permissions_survive(self):
        path = self.configs["claude"][0]
        target = self.home / "real settings.json"
        path.rename(target)
        path.symlink_to(target)
        result = self.run_toggle("dark")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue(path.is_symlink())
        self.assertEqual(json.loads(target.read_text())["theme"], "dark")
        self.assert_permissions_preserved()

    def test_auto_sets_agent_modes_without_changing_terminal(self):
        path = self.home / ".config/alacritty/alacritty.toml"
        before = path.read_bytes()
        result = self.run_toggle("auto")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stderr, "")
        self.assertEqual(path.read_bytes(), before)
        self.assertEqual(self.settings("claude")["theme"], "auto")
        self.assertEqual(self.settings("codex")["tui"]["theme"], "catppuccin-latte")
        self.assertEqual(self.settings("grok")["ui"]["theme"], "terminal-default")
        self.assertIs(self.settings("grok")["features"]["terminal_theme"], True)
        self.assert_permissions_preserved()

    def test_auto_does_not_claim_grok_success_if_feature_write_fails(self):
        self.shim("chmod", 'echo "injected chmod failure" >&2\nexit 1\n')
        before = self.configs["grok"][0].read_bytes()
        result = self.run_toggle("auto")
        self.assertNotEqual(result.returncode, 0, result.stdout)
        self.assertNotIn("  grok:", result.stdout)
        self.assertEqual(self.configs["grok"][0].read_bytes(), before)
        self.assert_permissions_preserved()


if __name__ == "__main__":
    unittest.main()
