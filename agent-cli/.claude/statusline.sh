#!/usr/bin/env bash
# Claude Code status line — two lines, mirroring the operator's Codex CLI status line fields.
#
# Line 1: model + reasoning effort · cwd · session name · project (repo) name · git branch · PR/MR
# Line 2: commits ahead / +adds -dels vs the default remote branch · context window % remaining ·
#         5h limit % remaining · 7d limit % remaining · CLI version · context window size ·
#         session tokens used
#
# NOT SHOWN — impossible from the documented statusLine JSON input:
#   "active permission mode" (default / acceptEdits / plan / bypassPermissions). That toggle is
#   in-memory session state. Claude Code's statusLine stdin (session_id, session_name, prompt_id,
#   transcript_path, cwd, model, workspace, version, output_style, context_window, effort,
#   thinking, rate_limits, prompt_cache, vim, agent, pr, worktree) has no field for it, and
#   settings.json's "permissions" key is a static allow/deny rule list, not the live toggle. If a
#   future CLI version adds a field for it, this can be revisited.
#
# Every other "omit when unavailable/unknown/zero" field is only appended to its line when
# present, so a missing value never leaves a stray " · " behind.
#
# Local git reads (branch, ahead-count, diffstat) are cheap, local-only (no fetch), and
# time-boxed via Python's subprocess `timeout=` — no external `timeout`/`gtimeout` binary needed
# (none ships with macOS by default). The one possible network call, `gh pr view`, only runs as a
# fallback when the JSON's own `.pr` field is absent; it is time-boxed the same way and its result
# is cached to a file for 60s so a slow or offline `gh` can't stall the prompt.

input=$(cat)
python3 - "$input" <<'PY'
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys
import time

try:
    d = json.loads(sys.argv[1])
except Exception:
    print("claude")
    print("")
    raise SystemExit


def dig(*paths, default=None):
    """First non-empty value among dotted paths."""
    for p in paths:
        cur = d
        for part in p.split("."):
            if isinstance(cur, dict) and part in cur:
                cur = cur[part]
            else:
                cur = None
                break
        if cur not in (None, "", {}, []):
            return cur
    return default


def tildify(path):
    """Swap $HOME for ~; otherwise show the path in full (no segment truncation)."""
    if not path:
        return ""
    home = os.path.expanduser("~")
    if path == home:
        return "~"
    if path.startswith(home + "/"):
        return "~/" + path[len(home) + 1:]
    return path


def human_tokens(n):
    try:
        n = int(n)
    except (TypeError, ValueError):
        return None
    if n >= 1_000_000:
        v, suffix = n / 1_000_000, "M"
    elif n >= 1_000:
        v, suffix = n / 1_000, "k"
    else:
        return str(n)
    s = f"{v:.1f}"
    if s.endswith(".0"):
        s = s[:-2]
    return s + suffix


def run(cmd, cwd, timeout=0.5):
    """Run a subprocess, time-boxed without needing an external `timeout` binary."""
    try:
        r = subprocess.run(
            cmd, cwd=cwd or ".", capture_output=True, text=True, timeout=timeout,
        )
    except Exception:
        return None
    if r.returncode != 0:
        return None
    return r.stdout


def get_branch(cwd):
    out = run(["git", "--no-optional-locks", "rev-parse", "--abbrev-ref", "HEAD"], cwd, 0.4)
    b = (out or "").strip()
    return b if b and b != "HEAD" else None


def get_default_ref(cwd):
    """Default branch, resolved from local refs only (no fetch)."""
    out = run(
        ["git", "--no-optional-locks", "symbolic-ref", "--quiet", "refs/remotes/origin/HEAD"],
        cwd, 0.4,
    )
    if out and out.strip():
        name = out.strip().rsplit("/", 1)[-1]
        if name:
            return f"origin/{name}"
    for candidate in ("origin/main", "origin/master"):
        if run(
            ["git", "--no-optional-locks", "rev-parse", "--verify", "--quiet", candidate], cwd, 0.4,
        ) is not None:
            return candidate
    return None


def get_branch_changes(cwd):
    default_ref = get_default_ref(cwd)
    if not default_ref:
        return None
    counts = run(
        ["git", "--no-optional-locks", "rev-list", "--left-right", "--count", f"{default_ref}...HEAD"],
        cwd, 0.5,
    )
    if not counts:
        return None
    fields = counts.split()
    if len(fields) != 2:
        return None
    try:
        ahead = int(fields[1])
    except ValueError:
        return None
    ins = dele = 0
    stat = run(["git", "--no-optional-locks", "diff", "--shortstat", f"{default_ref}...HEAD"], cwd, 0.5)
    if stat:
        m = re.search(r"(\d+) insertion", stat)
        if m:
            ins = int(m.group(1))
        m = re.search(r"(\d+) deletion", stat)
        if m:
            dele = int(m.group(1))
    return f"{ahead} ahead / +{ins} -{dele} vs {default_ref}"


def get_pr_via_gh(cwd, branch):
    """Fallback PR lookup for when the JSON has no `.pr` field. Cached 60s; ~0.4s time-box."""
    if not cwd or not branch or shutil.which("gh") is None:
        return None
    cache_dir = os.path.expanduser("~/.cache/claude-statusline")
    try:
        os.makedirs(cache_dir, exist_ok=True)
    except OSError:
        return None
    cache_file = os.path.join(cache_dir, f"pr-{hashlib.sha1(cwd.encode()).hexdigest()[:16]}.json")
    now = time.time()
    try:
        with open(cache_file) as f:
            cached = json.load(f)
        if now - cached.get("ts", 0) < 60:
            return cached.get("number")
    except Exception:
        pass
    out = run(["gh", "pr", "view", "--json", "number"], cwd, 0.4)
    number = None
    if out:
        try:
            number = json.loads(out).get("number")
        except Exception:
            number = None
    try:
        with open(cache_file, "w") as f:
            json.dump({"ts": now, "number": number}, f)
    except OSError:
        pass
    return number


cwd = dig("workspace.current_dir", "cwd", default="")
model = dig("model.display_name", "model.id", "model", default="?")
effort = dig("effort.level")
session_name = dig("session_name")
project_name = dig("workspace.repo.name")
version = dig("version", default="?")

branch = get_branch(cwd)

pr_field = d.get("pr") if isinstance(d.get("pr"), dict) else None
if pr_field and pr_field.get("number"):
    pr_num, pr_kind = pr_field["number"], pr_field.get("kind")
else:
    pr_num, pr_kind = get_pr_via_gh(cwd, branch), None
pr_str = ("pr:" + ("!" if pr_kind == "mr" else "#") + str(pr_num)) if pr_num else None

model_str = str(model) + (f" ({effort})" if effort else "")

line1 = [model_str]
if cwd:
    line1.append(tildify(cwd))
if session_name:
    line1.append(f"session:{session_name}")
if project_name:
    line1.append(f"project:{project_name}")
if branch:
    line1.append(f"git:{branch}")
if pr_str:
    line1.append(pr_str)

branch_changes = get_branch_changes(cwd) if branch else None
ctx_remaining = dig("context_window.remaining_percentage")
window_size = dig("context_window.context_window_size")
total_tokens = (dig("context_window.total_input_tokens", default=0) or 0) + (
    dig("context_window.total_output_tokens", default=0) or 0
)
five_hour_used = dig("rate_limits.five_hour.used_percentage")
seven_day_used = dig("rate_limits.seven_day.used_percentage")

line2 = []
if branch_changes:
    line2.append(branch_changes)
# Active permission mode intentionally omitted here -- see header note: not in the JSON input.
if ctx_remaining is not None:
    line2.append(f"ctx {ctx_remaining:.0f}% left")
if five_hour_used is not None:
    line2.append(f"5h {100 - five_hour_used:.0f}% left")
if seven_day_used is not None:
    line2.append(f"7d {100 - seven_day_used:.0f}% left")
line2.append(f"v{version}")
if window_size:
    ht = human_tokens(window_size)
    if ht:
        line2.append(f"win {ht}")
if total_tokens:
    ht = human_tokens(total_tokens)
    if ht:
        line2.append(f"used {ht}")

print(" · ".join(line1))
print(" · ".join(line2))
PY
