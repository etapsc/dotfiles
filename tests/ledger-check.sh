#!/usr/bin/env bash
set -uo pipefail
# BRIDGE ledger pre-flight (F66). The producer runs it before submitting a slice:
# docs/context.json at or under the 212 KiB cap (D-CONV-8), recent_decisions at
# most 5, handoff.watch_out at most 20, and a non-empty tests/slices/<slice>-verify.sh
# or -smoke.sh for every slice named on the command line.
#
#   bash tests/ledger-check.sh [Sxx ...]      e.g. bash tests/ledger-check.sh S84
#   make ledger-check SLICES="Sxx Syy"
#   bash tests/ledger-check.sh --ids          duplicate-ID check only (F70), e.g. from CI
#
# F70, F71: both modes also fail when one F, AT, S, UF, R or OQ ID is defined twice in
# docs/requirements.json and its previous_doc chain (definition sites only, object or array
# form; references never count; docs/context.json is not read). Numbers compare by value, so
# F3 and F03 are one ID; an execution.open_questions id of any other form compares as text.
# --ids needs only that chain and prints one OK line on a pass; default mode prints nothing
# more on a pass.
#
# Exit 0 with one `ledger-check OK:` line (the size and the two counts) when every
# check holds; exit 1 with one `ledger-check FAIL:` line per failed check; exit 2
# on a usage error or without python3. The ready-to-audit request records the
# command and its output; the gate reads that record as a warning that names the
# fix, never as a blocker (the product checks decide PASS or FAIL).
#
# BRIDGE-managed, pack-agnostic; byte-identical across packs and the repo root.
# Pack-owned: bridge.sh update refreshes it to the shipped content (it carries
# thresholds BRIDGE may change), unlike the add-only runners.
cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)" || exit 1

usage() { echo 'Usage: bash tests/ledger-check.sh [Sxx ...]   (or: make ledger-check SLICES="Sxx Syy");   bash tests/ledger-check.sh --ids   (duplicate-ID check only, for CI)'; }
case "${1:-}" in -h|--help) usage; exit 0 ;; esac
ids_only=0
if [ "${1:-}" = --ids ]; then
  [ "$#" -eq 1 ] || { echo "ledger-check: --ids takes no other argument" >&2; usage >&2; exit 2; }
  ids_only=1; shift
fi
for s in "$@"; do
  [[ "$s" =~ ^S[0-9]+$ ]] || { echo "ledger-check: not a slice id: $s" >&2; usage >&2; exit 2; }
done
command -v python3 >/dev/null 2>&1 || { echo "ledger-check: python3 is required" >&2; exit 2; }

# F70: one FAIL line per ID defined more than once, or one FAIL line for a broken chain; silent on a pass.
# Isolated mode (-I) keeps a planted json.py in the checkout off sys.path.
ids_check() {
  python3 -I - <<'PY'
import json, os, re, sys
ID = re.compile(r"^(F|AT|S|UF|R|OQ)([0-9]+)$")
SAFE = re.compile(r"^[A-Za-z0-9._/-]+$")

class Obj(dict):
    pass

def hook(pairs):  # keeps the raw pairs, so a key repeated inside one object stays visible
    obj = Obj(pairs)
    obj.pairs = pairs
    return obj

def load(path):
    try:
        with open(path, encoding="utf-8") as fh:
            doc = json.load(fh, object_pairs_hook=hook)
    except (OSError, ValueError):
        return None
    return doc if isinstance(doc, dict) else None

sites = {}

def define(value, site, text):  # key: series and number by value (F3 = F03); text: any other non-empty id as written
    m = ID.fullmatch(value) if isinstance(value, str) else None  # the whole string: "OQ1\n" is a text id
    if m:
        key = (m.group(1), m.group(2).lstrip("0") or "0")
    elif text and isinstance(value, str) and value:
        key = value
    else:
        return
    sites.setdefault(key, []).append((site, value if value.isprintable() else ascii(value)))

def container(c, where, text=False):  # object form: every key; array form: every object entry by id (else slice_id)
    if isinstance(c, Obj):
        items = [(k, v) for k, v in c.pairs]
    elif isinstance(c, list):
        items = [(e.get("id", e.get("slice_id")) if isinstance(e, dict) else None, e) for e in c]
    else:
        return []
    for n, (key, _) in enumerate(items, 1):
        define(key, f"{where} #{n}", text)
    return [(f"{where} #{n}", v) for n, (_, v) in enumerate(items, 1)]

def scan(doc, f):
    ex = doc.get("execution") if isinstance(doc.get("execution"), dict) else {}
    for name, c in (("features", doc.get("features")), ("acceptance_tests", doc.get("acceptance_tests")),
                    ("user_flows", doc.get("user_flows")), ("risks", doc.get("risks")),
                    ("execution.risks", ex.get("risks")),
                    ("execution.recommended_slices", ex.get("recommended_slices"))):
        for site, entry in container(c, f"{f} {name}"):
            if name == "features" and isinstance(entry, dict) and isinstance(entry.get("acceptance_tests"), list):
                container(entry["acceptance_tests"], f"{site} acceptance_tests")
    container(ex.get("open_questions"), f"{f} execution.open_questions", True)

f = "docs/requirements.json"
doc = load(f)
if doc is None:
    sys.exit(print(f"ledger-check FAIL: {f} missing or not valid JSON; duplicate IDs not checked") or 1)
seen = {os.path.normpath(f)}
while True:
    scan(doc, f)
    p = doc.get("previous_doc")
    if p is None:
        break
    if not (isinstance(p, str) and SAFE.match(p) and p[0] not in "/-" and ".." not in p.split("/")):
        sys.exit(print(f"ledger-check FAIL: {f}: previous_doc is not null or a relative path of letters, "
                       "digits and . _ / - without ..; fix the pointer") or 1)
    if os.path.normpath(p) in seen:
        sys.exit(print(f"ledger-check FAIL: {f}: previous_doc revisits {p}; fix the pointer") or 1)
    seen.add(os.path.normpath(p))
    nxt = load(p)
    if nxt is None:
        sys.exit(print(f"ledger-check FAIL: {p} (previous_doc of {f}) missing or not valid JSON; "
                       "fix the pointer or restore the file") or 1)
    f, doc = p, nxt
dups = [s for s in sites.values() if len(s) > 1]
for s in dups:  # each site names its spelling only when the spellings differ
    mixed = len({v for _, v in s}) > 1
    where = " and ".join(f"{site} as {v}" if mixed else site for site, v in s)
    print(f"ledger-check FAIL: {s[0][1]} defined {len(s)} times: {where}; renumber all but one and their references")
sys.exit(1 if dups else 0)
PY
}
if [ "$ids_only" -eq 1 ]; then
  ids_check || exit 1
  echo "ledger-check OK: no F, AT, S, UF, R or OQ ID defined twice in docs/requirements.json and its previous_doc chain"
  exit 0
fi

ctx=docs/context.json
CAP_KIB=212
MAX_RD=5
MAX_WO=20

# One line: size in bytes, recent_decisions count, handoff.watch_out count (missing keys count as 0;
# F71: a watch_out written as one non-empty string counts as 1).
nums="$(python3 - "$ctx" <<'PY'
import json, os, sys
path = sys.argv[1]
try:
    with open(path, encoding="utf-8") as fh:
        ctx = json.load(fh)
except (OSError, ValueError):
    sys.exit(1)
if not isinstance(ctx, dict):
    sys.exit(1)
rd = ctx.get("recent_decisions") or []
wo = (ctx.get("handoff") or {}).get("watch_out")
wo = 1 if isinstance(wo, str) and wo else len(wo or [])
print(os.path.getsize(path), len(rd), wo)
PY
)" || { echo "ledger-check FAIL: $ctx missing or not valid JSON"; exit 1; }
read -r size rd wo <<<"$nums"
[ -n "${wo:-}" ] || { echo "ledger-check FAIL: $ctx missing or not valid JSON"; exit 1; }
kib=$(( (size + 1023) / 1024 ))

fail=0
if [ "$size" -gt $((CAP_KIB * 1024)) ]; then
  echo "ledger-check FAIL: $ctx $kib KiB over the $CAP_KIB KiB cap (D-CONV-8); archive with .bridge/tools/archive.py"; fail=1
fi
if [ "$rd" -gt "$MAX_RD" ]; then
  echo "ledger-check FAIL: recent_decisions $rd over the window of $MAX_RD; drop the oldest entries"; fail=1
fi
if [ "$wo" -gt "$MAX_WO" ]; then
  echo "ledger-check FAIL: handoff.watch_out $wo over the window of $MAX_WO; expire met watch-outs"; fail=1
fi
for s in "$@"; do
  if [ ! -s "tests/slices/$s-verify.sh" ] && [ ! -s "tests/slices/$s-smoke.sh" ]; then
    echo "ledger-check FAIL: $s: no non-empty tests/slices/$s-verify.sh or tests/slices/$s-smoke.sh; seed the producer fence"; fail=1
  fi
done
ids_check || fail=1
[ "$fail" -eq 0 ] || exit 1

ok="ledger-check OK: $ctx $kib KiB (cap $CAP_KIB), recent_decisions $rd (max $MAX_RD), handoff.watch_out $wo (max $MAX_WO)"
[ "$#" -eq 0 ] || ok="$ok; producer scripts present for $*"
echo "$ok"
