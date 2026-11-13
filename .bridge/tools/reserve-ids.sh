#!/usr/bin/env bash
# reserve-ids.sh: reserve F, AT, S, UF, R and OQ numbers on a counter branch (F68, F71).
#   reserve-ids.sh SERIES=N... -m "title" [--branch <name>]   prints e.g. S104 F89 AT301-AT303,
#                                                             at least two digits each (F03)
#   reserve-ids.sh --sync    raise each counter to the highest ID on every pushed branch
#   reserve-ids.sh --init    create the counter branch from the same scan
# Exit codes: 0 done; 1 stopped before any push, nothing reserved; 2 not opted in (no
# docs/bridge-ids.conf), planning stays highest+1; 3 stopped at any point after a push attempt,
# a later retry's stop included: no IDs returned and the numbers may have been consumed.
# Messages go to stderr; stdout carries
# only the result. Uses bash, git and awk only. Design: docs/designs/S86-reserve-ids.md.
# F71: an ids file with the five F, AT, S, UF and R lines and no OQ line is a counter made before
# OQ was reserved; OQ is then seeded from the --sync scan and its line written in the same commit.
set -uo pipefail
export LC_ALL=C

SERIES="F AT S UF R OQ"
LEDGERS="docs/requirements.json docs/context.json"
LIMIT=999999999

say() { printf 'reserve-ids: %s\n' "$*" >&2; }
die() { local rc="$1"; shift; say "$*"; exit "$rc"; }
usage() { die 1 "$1. Usage: reserve-ids.sh SERIES=N... -m \"title\" [--branch <name>] | --sync | --init"; }

# 1. Arguments, in pure bash: no git call happens before they are valid.
mode=reserve modeflag="" title="" has_title="" branch="" has_branch="" reqs="" named=" "
re_req='^(F|AT|S|UF|R|OQ)=[1-9][0-9]{0,2}$'
while [ $# -gt 0 ]; do
  case "$1" in
    --sync|--init)
      [ -z "$modeflag" ] || usage "$modeflag and $1 exclude each other"
      modeflag="$1"; mode="${1#--}" ;;
    -m)
      [ $# -ge 2 ] || usage "-m needs a title"
      title="$2"; has_title=1; shift ;;
    --branch)
      [ $# -ge 2 ] || usage "--branch needs a name"
      branch="$2"; has_branch=1; shift ;;
    *=*)
      [[ $1 =~ $re_req ]] || usage "invalid request '$1': the series is one of $SERIES and the count is 1 to 999"
      case "$named" in *" ${1%%=*} "*) usage "invalid request '$1': ${1%%=*} is requested twice" ;; esac
      named="$named${1%%=*} "; reqs="${reqs:+$reqs }$1" ;;
    *) usage "unknown argument '$1'" ;;
  esac
  shift
done
if [ "$mode" = reserve ]; then
  [ -n "$reqs" ] || usage "no request: name at least one of $SERIES, for example S=1"
  [ -n "$has_title" ] || usage "-m \"title\" is required"
  [ -n "$title" ] || usage "the -m title is empty"
  [[ $title != *[[:cntrl:]]* ]] || usage "the -m title must be one line without control characters"
  if [ -n "$has_branch" ] && { [ -z "$branch" ] || [[ $branch == *[[:space:][:cntrl:]]* ]]; }; then
    usage "--branch must be non-empty, without whitespace or control characters"
  fi
elif [ -n "$reqs$has_title$has_branch" ]; then
  usage "$modeflag takes no request, no -m and no --branch"
fi

# 2. Opt-in: the first git call is this read-only one.
top=$(git rev-parse --show-toplevel 2>/dev/null) && [ -n "$top" ] || die 1 "not inside a git working tree; nothing reserved"
conf="$top/docs/bridge-ids.conf"
[ -e "$conf" ] || die 2 "this repository is not opted in (no docs/bridge-ids.conf): highest+1 applies"
badconf() { die 1 "docs/bridge-ids.conf: $1. The repository is opted in, so highest+1 does not apply; fix the file. Nothing reserved"; }
ref="" remote="" n=0
while IFS= read -r line || [ -n "$line" ]; do
  n=$((n + 1))
  case "$line" in
    ref=*) [ -z "$ref" ] || badconf "ref= is given twice"; ref="${line#ref=}"; [ -n "$ref" ] || badconf "ref= is empty" ;;
    remote=*) [ -z "$remote" ] || badconf "remote= is given twice"; remote="${line#remote=}"; [ -n "$remote" ] || badconf "remote= is empty" ;;
    *) badconf "line $n is neither ref=<branch> nor remote=<name>" ;;
  esac
done < "$conf"
[ -n "$ref" ] || badconf "it has no ref= line"
remote="${remote:-origin}"
case "$ref" in -*) badconf "ref must not start with -" ;; esac
git check-ref-format "refs/heads/$ref" >/dev/null 2>&1 || badconf "ref is not a valid branch name"
re_remote='^[A-Za-z0-9][A-Za-z0-9._-]*$'
[[ $remote =~ $re_remote ]] || badconf "remote must be a remote name (letters, digits, dot, underscore, dash)"

# 3. Dispatch on the branch's presence. Messages name the remote, never its URL.
git ls-remote --exit-code -q "$remote" "refs/heads/$ref" >/dev/null
rc=$?
case "$mode:$rc" in
  init:2) ;;
  init:0) die 1 "$ref already exists on remote $remote; use --sync; nothing changed" ;;
  *:2) die 1 "remote $remote has no $ref branch; run reserve-ids.sh --init once; nothing reserved" ;;
  *:0) ;;
  *) die 1 "registry unreachable: cannot read $ref on remote $remote; nothing reserved" ;;
esac

# 4. Ledger maxima: whole quoted IDs ("S110") per file, and one previous_doc verdict
# (path, null, absent or bad); the first "previous_doc" in a file decides.
SCAN_AWK='
BEGIN { n = split(acc, a, " ")
        for (i = 1; i <= n; i++) { e = index(a[i], "="); o[i] = substr(a[i], 1, e - 1); m[o[i]] = substr(a[i], e + 1) + 0 } }
{ t = $0
  if (pv == "" && (p = index(t, "\"previous_doc\"")) > 0) {
    r = substr(t, p + 14); sub(/^[ \t]+/, "", r)
    if (substr(r, 1, 1) != ":") pv = "bad"
    else { r = substr(r, 2); sub(/^[ \t]+/, "", r); q = index(substr(r, 2), "\"")
      if (substr(r, 1, 4) == "null" && substr(r, 5, 1) !~ /[A-Za-z0-9_]/) pv = "null"
      else if (substr(r, 1, 1) == "\"" && q > 1) pv = "path " substr(r, 2, q - 1)
      else pv = "bad" } }
  while (match(t, /"(F|AT|S|UF|R|OQ)[0-9]+"/)) {
    id = substr(t, RSTART + 1, RLENGTH - 2); t = substr(t, RSTART + RLENGTH)
    k = id; sub(/[0-9]+$/, "", k); d = substr(id, length(k) + 1); sub(/^0+/, "", d)
    if (length(d) > 9) { if (big == "") big = id } else if (d + 0 > m[k]) m[k] = d + 0 } }
END { if (big != "") print "big " big
      for (i = 1; i <= n; i++) s = s (i > 1 ? " " : "") o[i] "=" m[o[i]]
      print "acc " s; print "ptr " (pv == "" ? "absent" : pv) }'
ZERO="F=0 AT=0 S=0 UF=0 R=0 OQ=0"
acc="$ZERO"

chain() {  # $1 git ref, or "" for the working tree; $2 where (for messages); $3 current ledger. rc 2: absent
  local r="$1" where="$2" f="$3" seen=" " out line next
  while [ -n "$f" ]; do
    case "$seen" in *" $f "*) die 1 "$where: the previous_doc chain revisits $f; fix the pointer; nothing reserved" ;; esac
    if [ -z "$r" ]; then
      if [ ! -f "$top/$f" ]; then
        [ "$seen" = " " ] && return 2
        die 1 "$where: a previous_doc names $f, which is missing; nothing reserved"
      fi
      out=$(awk -v acc="$acc" "$SCAN_AWK" < "$top/$f") || die 1 "$where: cannot read $f; nothing reserved"
    else
      if ! git cat-file -e "$r:$f" 2>/dev/null; then
        [ "$seen" = " " ] && return 2
        die 1 "$where: a previous_doc names $f, which is missing on that branch; nothing reserved"
      fi
      out=$(git show "$r:$f" | awk -v acc="$acc" "$SCAN_AWK") || die 1 "$where: cannot read $f; nothing reserved"
    fi
    seen="$seen$f " next=""
    while IFS= read -r line; do
      case "$line" in
        "big "*) die 1 "$where: $f holds ${line#big }, above $LIMIT; nothing reserved" ;;
        "acc "*) acc="${line#acc }" ;;
        "ptr path "*) next="${line#ptr path }"
          case "$next" in /*|-*|*..*|*[!A-Za-z0-9._/-]*)
            die 1 "$where: the previous_doc in $f is not a relative path of letters, digits and . _ / - without ..; nothing reserved" ;;
          esac ;;
        "ptr bad") die 1 "$where: $f has a previous_doc this reader cannot parse; write it on one line as \"previous_doc\": \"<path>\" or null; nothing reserved" ;;
      esac
    done <<<"$out"
    f="$next"
  done
  return 0
}

scan_branches() {  # raises acc to the highest ID on every pushed branch of the remote
  local heads r name missing f
  git fetch -q "$remote" "+refs/heads/*:refs/remotes/$remote/*" >&2 || die 1 "cannot fetch the branches of remote $remote; nothing changed"
  heads=$(git for-each-ref --format='%(refname)' "refs/remotes/$remote/") || die 1 "cannot list the branches of remote $remote"
  while IFS= read -r r; do
    name="${r#refs/remotes/"$remote"/}"
    if [ -z "$r" ] || [ "$name" = HEAD ] || [ "$name" = "$ref" ]; then continue; fi
    missing=""
    for f in $LEDGERS; do chain "$r" "branch $name" "$f" || missing="$missing $f"; done
    if [ "$missing" = " $LEDGERS" ]; then say "branch $name has no ledgers; skipped"
    elif [ -n "$missing" ]; then say "branch $name has no$missing"; fi
  done <<<"$heads"
}
# The OQ value of that scan, for a counter made before F71. A subshell: the working tree's acc
# stays as it is, and a stop inside the scan becomes a failed substitution.
oq_seed() ( acc="$ZERO"; scan_branches; printf '%s\n' "${acc##*OQ=}" )

if [ "$mode" = reserve ]; then
  for f in $LEDGERS; do chain "" "working tree" "$f" || say "no $f in the working tree; skipped"; done
  if [ -z "$has_branch" ]; then
    branch=$(git symbolic-ref --short -q HEAD 2>/dev/null) && [ -n "$branch" ] || branch=detached
  fi
else
  scan_branches
fi

# 5 and 6. Write the counters with plumbing (HEAD, index and working tree untouched) and push.
host="${HOSTNAME:-host}"; host="${host//[!A-Za-z0-9._-]/_}"
# A push whose reply is lost may still have landed, so once one is attempted no later stop,
# on any retry, may say nothing was reserved: stop() keeps exit 3 from then on.
pushed=""
stop() {  # $1 the reason: exit 1 before any push attempt, exit 3 after one
  [ -z "$pushed" ] || die 3 "$1; a push earlier in this run may have landed: no IDs returned; these numbers may have been consumed"
  die 1 "$1; nothing reserved"
}
write() {  # $1 parent ("" for none), $2 message: sets commit
  local blob tree
  blob=$(printf '%s\n' "${newv[@]}" | git hash-object -w --stdin) || stop "cannot write the ids blob"
  tree=$(printf '100644 blob %s\tids\n' "$blob" | git mktree) || stop "cannot write the ids tree"
  if [ -n "$1" ]; then commit=$(git commit-tree "$tree" -p "$1" -m "$2"); else commit=$(git commit-tree "$tree" -m "$2"); fi \
    || stop "cannot write the commit"
}
push() { pushed=1; git push -q "$remote" "$commit:refs/heads/$ref" >&2; }

if [ "$mode" = init ]; then
  read -r -a newv <<<"$acc"
  write "" "init $acc attempt=$host-$$-$RANDOM$RANDOM"
  push || die 3 "push failed: $ref may now exist on remote $remote; run reserve-ids.sh --sync; no counters returned"
  printf '%s\n' "$acc"
  exit 0
fi

IDS_AWK='
BEGIN { n = split("F AT S UF R OQ", o, " "); for (i = 1; i <= n; i++) known[o[i]] = 1
        c = split(sc, a, " "); for (i = 1; i <= c; i++) { e = index(a[i], "="); scan[substr(a[i], 1, e - 1)] = substr(a[i], e + 1) + 0 } }
{ if (bad != "") next
  if ($0 !~ /^[A-Z]+=[0-9]+$/) { bad = "line " NR " is not SERIES=N"; next }
  e = index($0, "="); k = substr($0, 1, e - 1); v = substr($0, e + 1)
  if (!(k in known)) bad = "line " NR ": " k " is not one of F AT S UF R OQ"
  else if (k in old) bad = k " appears twice"
  else if (length(v) > 9) bad = k " has more than nine digits"
  else old[k] = v + 0 }
END { for (i = 1; i < n && bad == ""; i++) if (!(o[i] in old)) bad = "no " o[i] " row"
      if (bad != "") { print "bad " bad; exit 1 }
      if (!("OQ" in old)) {  # a counter made before F71: --sync starts OQ at 0, a reservation at the seed
        if (mode == "sync") rise = 1; else if (seed == "") { print "seed"; exit 0 }
        old["OQ"] = seed + 0 }
      r = split(req, q, " ")
      for (i = 1; i <= r; i++) { e = index(q[i], "="); k = substr(q[i], 1, e - 1); add[k] = substr(q[i], e + 1) + 0
        item = sprintf("%s%02d", k, old[k] + 1); if (add[k] > 1) item = item sprintf("-%s%02d", k, old[k] + add[k])
        list = list (i > 1 ? " " : "") item }
      for (i = 1; i <= n; i++) { k = o[i]; nv = old[k] + add[k]
        if (mode == "sync" && scan[k] > nv) { nv = scan[k]; rise = 1 }
        if (nv > lim) { print "big " k "=" nv; exit 1 }
        if (mode == "reserve" && scan[k] > old[k]) ahead = ahead (ahead == "" ? "" : ", ") sprintf("%s%02d", k, scan[k]) " (counter " k "=" old[k] ")"
        s = s (i > 1 ? " " : "") k "=" nv }
      if (ahead != "") { print "ahead " ahead; exit 1 }
      print "new " s
      if (mode == "reserve") print "list " list; else print "rise " (rise ? 1 : 0) }'

track="refs/remotes/$remote/$ref"
fetch_ref() { git fetch -q "$remote" "+refs/heads/$ref:$track" >&2; }
ids_awk() { git show "$base:ids" | awk -v mode="$mode" -v req="$reqs" -v sc="$acc" -v lim="$LIMIT" -v seed="$seed" "$IDS_AWK"; }
try=1 seed=""
while :; do
  fetch_ref || stop "cannot fetch $ref from remote $remote"
  base=$(git rev-parse -q --verify "$track^{commit}") || stop "cannot resolve $ref after the fetch"
  git cat-file -e "$base:ids" 2>/dev/null || stop "malformed $ref at ${base:0:12}: it has no ids file"
  res=$(ids_awk)
  if [ "$res" = seed ]; then
    seed=$(oq_seed) || stop "cannot seed OQ from the branches of remote $remote"
    res=$(ids_awk)
  fi
  counters="" out="" rise=""
  while IFS= read -r line; do
    case "$line" in
      "bad "*) stop "malformed ids file on $ref at ${base:0:12}: ${line#bad }" ;;
      "big "*) stop "the counter ${line#big } would pass $LIMIT" ;;
      "ahead "*) stop "the ledgers are ahead of the counter on $remote/$ref: ${line#ahead }. Push the branch that holds them, then run reserve-ids.sh --sync" ;;
      "new "*) counters="${line#new }" ;;
      "list "*) out="${line#list }" ;;
      "rise "*) rise="${line#rise }" ;;
    esac
  done <<<"$res"
  [ -n "$counters" ] || stop "cannot read the ids file on $ref at ${base:0:12}"
  read -r -a newv <<<"$counters"
  token="$host-$$-$RANDOM$RANDOM"
  if [ "$mode" = sync ]; then
    out="$counters"
    if [ "$rise" != 1 ]; then
      printf '%s\n' "$out"
      say "every counter is already at or above the highest ID found; nothing to raise"
      exit 0
    fi
    write "$base" "sync $counters attempt=$token"
  else
    write "$base" "reserve $out branch=$branch attempt=$token: $title"
  fi
  if push; then printf '%s\n' "$out"; exit 0; fi
  fetch_ref || die 3 "push failed and $ref cannot be read from remote $remote: result unconfirmed; no IDs returned; these numbers may have been consumed"
  now=$(git rev-parse -q --verify "$track^{commit}") || die 3 "push failed and $ref cannot be resolved: result unconfirmed; no IDs returned; these numbers may have been consumed"
  [ "$now" != "$base" ] || die 3 "push failed and $ref on remote $remote did not move: no IDs returned; these numbers may have been consumed"
  [ "$try" -lt 5 ] || die 3 "the tip of $ref moved 5 times; no IDs returned; these numbers may have been consumed; try again"
  try=$((try + 1))
  say "the tip of $ref moved (another reservation won, or this run's push landed and its reply was lost); recounting, try $try of 5"
done
