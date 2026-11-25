#!/usr/bin/env python3
"""Exercise new-zellij-audit-layout.sh from a disposable copy, never the repo's layouts."""

import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
import unittest


SCRIPT = Path(__file__).resolve().parents[1] / "bin/new-zellij-audit-layout.sh"
TAB = re.compile(r'^    tab name="([^"]*)"(?: cwd="([^"]*)")?( focus=true)?$')


class AuditLayoutTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory(prefix="audit-layout-test-")
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name).resolve()
        (self.root / "bin").mkdir()
        self.script = self.root / "bin" / SCRIPT.name
        shutil.copy2(SCRIPT, self.script)
        self.layouts = self.root / "zellij/.config/zellij/layouts/projects"
        self.work = self.root / "work"
        self.repos = {}
        for name in ("sn-api-server", "lumescope", "lumera-uploader"):
            path = self.work / name
            path.mkdir(parents=True)
            self.repos[name] = path
        self.env = dict(os.environ, HOME=str(self.root))

    def run_script(self, answers, *args):
        stdin = "".join(line + "\n" for line in answers)
        return subprocess.run(
            [str(self.script), *args],
            input=stdin,
            capture_output=True,
            text=True,
            env=self.env,
            check=False,
        )

    def tabs(self, name):
        text = (self.layouts / f"{name}.kdl").read_text()
        return [m.groups() for m in map(TAB.match, text.splitlines()) if m], text

    def test_three_projects_give_seven_tabs_in_pairs_plus_shell(self):
        snapi, scope, uploader = (str(self.repos[n]) for n in self.repos)
        result = self.run_script(
            ["3", snapi, "snapi", scope, "", uploader, ""], "audit-tools"
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("(7 tabs, session audit-tools)", result.stdout)
        tabs, text = self.tabs("audit-tools")
        self.assertEqual(
            tabs,
            [
                ("snapi Auditor", snapi, " focus=true"),
                ("snapi Provider", snapi, None),
                ("lumescope Auditor", scope, None),
                ("lumescope Provider", scope, None),
                ("lumera-uploader Auditor", uploader, None),
                ("lumera-uploader Provider", uploader, None),
                ("Shell", None, None),
            ],
        )
        self.assertIn(f'    cwd "{self.work}"\n', text)
        self.assertIn(f"// shell: {self.work}\n", text)
        self.assertIn(f"// project: snapi {snapi}\n", text)
        self.assertIn(f"// project: lumescope {scope}\n", text)
        self.assertIn('session_name "audit-tools"\nattach_to_session true\n', text)
        self.assertIn('plugin location="tab-bar"', text)

    def test_single_project_shell_opens_in_its_parent_and_tilde_expands(self):
        result = self.run_script(["1", "~/work/lumescope", ""], "audit-one")
        self.assertEqual(result.returncode, 0, result.stderr)
        tabs, text = self.tabs("audit-one")
        scope = str(self.repos["lumescope"])
        self.assertEqual(
            tabs,
            [
                ("lumescope Auditor", scope, " focus=true"),
                ("lumescope Provider", scope, None),
                ("Shell", None, None),
            ],
        )
        self.assertIn(f'    cwd "{self.work}"\n', text)

    def test_projects_in_different_trees_share_their_deepest_common_parent(self):
        other = self.root / "elsewhere/deep/repo"
        other.mkdir(parents=True)
        result = self.run_script(
            ["2", str(self.repos["lumescope"]), "", str(other), ""], "audit-mixed"
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        _, text = self.tabs("audit-mixed")
        self.assertIn(f'    cwd "{self.root}"\n', text)

    def test_existing_layout_needs_force_and_is_left_alone_without_it(self):
        self.layouts.mkdir(parents=True)
        target = self.layouts / "audit-web.kdl"
        target.write_text("old layout\n")
        answers = ["1", str(self.repos["lumescope"]), ""]
        refused = self.run_script(answers, "audit-web")
        self.assertNotEqual(refused.returncode, 0)
        self.assertIn("--force", refused.stderr)
        self.assertEqual(target.read_text(), "old layout\n")
        forced = self.run_script(answers, "--force", "audit-web")
        self.assertEqual(forced.returncode, 0, forced.stderr)
        self.assertEqual(len(self.tabs("audit-web")[0]), 3)

    def test_invalid_answers_are_refused_without_writing_a_layout(self):
        scope = str(self.repos["lumescope"])
        quoted = self.work / 'has"quote'
        quoted.mkdir()
        cases = {
            "zero projects": ["0"],
            "not a number": ["two"],
            "too many projects": ["21"],
            "overflowing count": ["9223372036854775808"],
            "missing directory": ["1", str(self.work / "nope")],
            "empty path": ["1", ""],
            "quote in path": ["1", str(quoted)],
            "space in label": ["1", scope, "my label"],
            "quote in label": ["1", scope, 'a"b'],
            "duplicate label": ["2", scope, "x", str(self.repos["lumera-uploader"]), "x"],
            "input ends early": ["2", scope, ""],
        }
        for case, answers in cases.items():
            with self.subTest(case):
                result = self.run_script(answers, "audit-bad")
                self.assertNotEqual(result.returncode, 0)
                self.assertIn("error:", result.stderr)
                self.assertFalse((self.layouts / "audit-bad.kdl").exists())

    def test_session_option_names_the_session_independently_of_the_file(self):
        result = self.run_script(
            ["1", str(self.repos["lumescope"]), "scope"],
            "--force", "--session", "Tools", "audit-tools",
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("session Tools", result.stdout)
        _, text = self.tabs("audit-tools")
        self.assertIn("// session: Tools\n", text)
        self.assertIn('session_name "Tools"\nattach_to_session true\n', text)
        self.assertNotIn('session_name "audit-tools"', text)

    def test_unsafe_layout_names_and_wrong_arguments_are_refused(self):
        for args in (
            ["a/b"], ['x"y'], [".hidden"], [""], [], ["one", "two"],
            ["--session", "a b", "audit-x"], ["--session", 'q"t', "audit-x"],
            ["--session", "", "audit-x"], ["audit-x", "--session"],
            ["--session"], ["--bogus", "audit-x"],
        ):
            with self.subTest(args=args):
                result = self.run_script(["1", str(self.repos["lumescope"]), ""], *args)
                self.assertNotEqual(result.returncode, 0)
        self.assertFalse(self.layouts.exists() and any(self.layouts.iterdir()))


if __name__ == "__main__":
    unittest.main()
