#!/usr/bin/env bash
# .bridge/relay/wait.sh: wait for the next commit, on any ref but refs/stash or on a
# worktree HEAD, that changes a path, then print "<full SHA> <subject>" of the
# newest such commit.
# Part of BRIDGE Relay (.bridge/relay/README.md). Bash 3.2 compatible.
#
# Read-only: it runs only git rev-parse, rev-list and log. It never runs git
# status, fetch or anything else that writes, and it creates no files.
#
# A commit qualifies when `git rev-list --exclude=refs/stash --all` reaches it,
# it changes <path> (relative to the repository root) and it is not old. Old
# means reachable from a ref tip or HEAD when the wait starts (default),
# reachable from <sha> (--after <sha>), or nothing at all (--after none). A git
# stash never qualifies. Any other ref does, including a branch that is not an
# ancestor of --after.
#
# Exit codes: 0 found (printed on stdout), 1 a git command failed, 2 missing or
# invalid argument or not inside a git work tree, 3 timed out.
set -u

usage() {
  cat <<'EOF'
Usage: bash .bridge/relay/wait.sh <path> [--after <sha>|none] [--interval-sec N] [--timeout-min N]
       bash .bridge/relay/wait.sh --help

Waits for the next commit, on any ref but refs/stash or on a worktree HEAD,
that changes <path> (relative to the repository root), then prints its full
SHA and subject.

  --after <sha>     <sha> and its ancestors are old (default: every commit
                    reachable from a ref or HEAD when the wait starts is old)
  --after none      nothing is old: any commit that changes <path> ends the wait
  --interval-sec N  seconds between checks (default 60, a 60-second interval)
  --timeout-min N   minutes before giving up (default 720, a 12-hour timeout)

Exit codes: 0 commit found, 1 a Git command failed, 2 missing or invalid
argument or not inside a Git work tree, 3 timed out. It never writes to the
repository.
EOF
}

bad() { printf '.bridge/relay/wait.sh: %s\n' "$1" >&2; usage >&2; exit 2; }
is_count() { case "$1" in ''|0*|*[!0-9]*) return 1 ;; esac; }

path='' after='' interval=60 timeout=720
while [ $# -gt 0 ]; do
  case "$1" in
    --help|-h) usage; exit 0 ;;
    --after|--interval-sec|--timeout-min)
      [ $# -ge 2 ] || bad "$1 needs a value"
      case "$2" in ''|-*) bad "$1 needs a value" ;; esac
      case "$1" in
        --after) after="$2" ;;
        --interval-sec) is_count "$2" || bad "--interval-sec needs a positive integer"; interval="$2" ;;
        --timeout-min) is_count "$2" || bad "--timeout-min needs a positive integer"; timeout="$2" ;;
      esac
      shift 2 ;;
    -*) bad "unknown option: $1" ;;
    *) [ -z "$path" ] || bad "unexpected argument: $1"; path="$1"; shift ;;
  esac
done
[ -n "$path" ] || bad "missing <path>"

[ "$(git rev-parse --is-inside-work-tree 2>/dev/null)" = true ] || bad "not inside a Git work tree"
cd "$(git rev-parse --show-toplevel)" || exit 1

case "$after" in
  none) old='' ;;
  '') old="$(git rev-list --no-walk --exclude=refs/stash --all)" || exit 1 ;;
  *) old="$(git rev-parse --verify --quiet "$after^{commit}")" || bad "--after: not a commit: $after" ;;
esac

deadline=$((SECONDS + timeout * 60))
printf '.bridge/relay/wait.sh: waiting for a new commit that changes %s (every %s s, up to %s min)\n' \
  "$path" "$interval" "$timeout" >&2
while :; do
  # shellcheck disable=SC2086  # $old is a whitespace-separated list of SHAs
  new="$(git rev-list -n 1 --exclude=refs/stash --all --not $old -- "$path")" || exit 1
  if [ -n "$new" ]; then
    git log -1 --format='%H %s' "$new" || exit 1
    exit 0
  fi
  if [ "$SECONDS" -ge "$deadline" ]; then
    printf '.bridge/relay/wait.sh: timed out after %s min; no new commit changes %s\n' "$timeout" "$path" >&2
    exit 3
  fi
  left=$((deadline - SECONDS))
  if [ "$left" -lt "$interval" ]; then sleep "$left"; else sleep "$interval"; fi
done
