#!/usr/bin/env python3
"""Move old items of docs/context.json and docs/requirements.json into docs/archive/.

    python3 .bridge/tools/archive.py            show what would move; writes nothing
    python3 .bridge/tools/archive.py --write    do it

A feature moves when it is done or removed in both files and is not in the current or
next slice; its tests, status and evidence go with it. History entries older than the
last 3 of each list move, unless they await feedback, list a feature that stays or name
the current or next slice. Closed discrepancies and open questions move too.
Archive files have the same schema as the current files. Every file in the chain carries
"doc_state" and "previous_doc" (the next older file, or null). Python 3.9+, stdlib only.
"""
import json
import os
import re
import subprocess
import sys

DOCS = ("context", "requirements")
DONE = ("done", "removed")
CLOSED = ("resolved", "wont-fix", "superseded", "answered", "withdrawn")  # the closed record statuses
LEGACY = ("resolved", "closed", "fixed", "answered", "withdrawn")  # how older records began their status
HISTORY = ("slice_history", "gate_history", "eval_history", "feedback_history")
RECENT = 3  # the last entries of each history list always stay
SLICE_KEYS = ("id", "slice_id", "slice", "slices", "slice_range")
SLICE_ID = re.compile(r"\bS\d+\b")
SCHEMA_KEYS = ("schema", "schema_version")


class Refusal(Exception):
    """A one-line reason to stop."""


def git(*args):
    return subprocess.run(["git", *args], capture_output=True, text=True, check=True).stdout.strip()


def load(path):
    def no_duplicates(pairs):
        obj = {}
        for key, value in pairs:
            if key in obj:
                raise Refusal(f"{path}: duplicate key {key!r}")
            obj[key] = value
        return obj

    try:
        with open(path, encoding="utf-8") as f:
            doc = json.load(f, object_pairs_hook=no_duplicates)
    except OSError as e:
        raise Refusal(f"{path}: cannot read ({e.strerror})")
    except ValueError as e:
        raise Refusal(f"{path}: invalid JSON ({e})")
    if not isinstance(doc, dict):
        raise Refusal(f"{path}: not a JSON object")
    return doc


def dump(path, doc, mode):
    with open(path, mode, encoding="utf-8") as f:
        f.write(json.dumps(doc, indent=2, ensure_ascii=False) + "\n")


def get(doc, path):
    for key in path:
        doc = doc.get(key) if isinstance(doc, dict) else None
    return doc


def listed(item, key):
    """The IDs an item lists under key, as strings or as objects with an "id"."""
    values = item.get(key) if isinstance(item, dict) else None
    if not isinstance(values, list):
        return []
    ids = (v.get("id") if isinstance(v, dict) else v for v in values)
    return [i for i in ids if i is not None]


def rows(section):
    """(key, id, item) for an object map (key is the ID) or an array (key is the index)."""
    if isinstance(section, dict):
        return [(k, k, v) for k, v in section.items()]
    if isinstance(section, list):
        return [(i, x.get("id", x.get("feature_id")) if isinstance(x, dict) else None, x)
                for i, x in enumerate(section)]
    return None


def slice_id(entry):
    return entry.get("id", entry.get("slice_id"))


def statuses(section_rows):
    """{feature ID: status}; an item is a status string or an object with "status"."""
    return {fid: item.get("status") if isinstance(item, dict) else item
            for _, fid, item in section_rows if fid is not None}


def closed(entry):
    """A discrepancy or open question is closed when its status is one of CLOSED or, in legacy
    data, its resolution starts with "resolved" or its status with one of LEGACY (any case)."""
    status, text = entry.get("status"), entry.get("resolution")
    status = status.strip().lower() if isinstance(status, str) else ""
    return (status in CLOSED or status.startswith(LEGACY)
            or (isinstance(text, str) and text.lower().startswith("resolved")))


def plan(ctx, req):
    """Return ({doc name: [(section path, keys or indices that move)]}, notes)."""
    notes = []
    status, features = rows(ctx.get("feature_status", {})), rows(req.get("features", {}))
    slices = get(req, ("execution", "recommended_slices"))
    slices = slices if isinstance(slices, list) else []

    # Features in the current or next slice stay.
    pinned_slices, pinned = set(), set()
    for s in (ctx.get("current_slice"), ctx.get("next_slice")):
        if isinstance(s, dict):
            pinned_slices.add(slice_id(s))
            pinned.update(listed(s, "features"))
        elif isinstance(s, str):
            pinned_slices.add(s)
    pinned_slices -= {None, ""}
    for s in slices:
        if isinstance(s, dict) and slice_id(s) in pinned_slices:
            pinned.update(listed(s, "features"))

    # A feature moves when it is done or removed in both files (a missing requirements
    # status agrees). A feature archived by an earlier run is in neither current file,
    # so it counts as moved. If either section has another shape, no feature moves and
    # every feature counts as staying.
    moved, staying = set(), None
    if status is not None and features is not None:
        req_status = statuses(features)
        moved = {fid for fid, st in statuses(status).items()
                 if st in DONE and req_status.get(fid) in (None,) + DONE and fid not in pinned}
        staying = (set(statuses(status)) | set(req_status) | pinned) - moved

    def stays(fid):
        return staying is None or fid in staying

    def all_moved(entry):
        fids = listed(entry, "features")
        return bool(fids) and not any(map(stays, fids))

    def old_slice(entry):
        return all_moved(entry) and slice_id(entry) not in pinned_slices

    # An acceptance test moves when something lists it (a feature, a recommended slice
    # or its own feature_id) and nothing that lists it stays.
    kept = {}
    for _, fid, f in features or []:
        for aid in listed(f, "acceptance_tests"):
            kept.setdefault(aid, []).append(stays(fid))
    for s in slices:
        for aid in listed(s, "acceptance_tests"):
            kept.setdefault(aid, []).append(not old_slice(s))
    for _, aid, test in rows(req.get("acceptance_tests", {})) or []:
        if isinstance(test, dict) and test.get("feature_id") is not None:
            kept.setdefault(aid, []).append(stays(test["feature_id"]))
    moved_tests = {aid for aid, flags in kept.items() if not any(flags)}

    def old_history(entry):
        named = SLICE_ID.findall(" ".join(str(entry.get(k, "")) for k in SLICE_KEYS))
        return (entry.get("awaiting_feedback") is not True
                and not any(map(stays, listed(entry, "features")))
                and not pinned_slices.intersection(named))

    moves = {name: [] for name in DOCS}

    def add(name, doc, path, ids=None, rule=None, recent=0):
        """Queue the items of one section that move: by ID, or by a rule on each array entry."""
        section = get(doc, path)
        if section is None:
            return
        if not isinstance(section, list) and not (ids is not None and isinstance(section, dict)):
            notes.append(f"docs/{name}.json: {'.'.join(path)} has an unsupported shape; left in place")
            return
        if ids is not None:
            picks = [key for key, item_id, _ in rows(section) if item_id in ids]
        else:
            old = len(section) - recent
            picks = [i for i, x in enumerate(section) if i < old and isinstance(x, dict) and rule(x)]
        if picks:
            moves[name].append((path, picks))

    def records(name, doc, path):
        """Queue a record list's closed entries. An entry whose status is outside the vocabulary
        (neither open nor closed) stays and is named; one with no status is open and is not."""
        section = get(doc, path)
        for i, entry in enumerate(section if isinstance(section, list) else []):
            value = entry.get("status") if isinstance(entry, dict) else None
            if isinstance(value, str) and value.strip().lower() != "open" and not closed(entry):
                notes.append(f'docs/{name}.json: {".".join(path)} {entry.get("id", i)} has status '
                             f'"{value}", outside the vocabulary; left in place')
        add(name, doc, path, rule=closed)

    add("context", ctx, ("feature_status",), ids=moved)
    add("context", ctx, ("evidence",), ids=moved | moved_tests)
    for key in HISTORY:
        add("context", ctx, (key,), rule=old_history, recent=RECENT)
    records("context", ctx, ("discrepancies",))
    add("requirements", req, ("features",), ids=moved)
    add("requirements", req, ("acceptance_tests",), ids=moved_tests)
    add("requirements", req, ("execution", "recommended_slices"), rule=old_slice)
    records("requirements", req, ("execution", "open_questions"))
    return moves, notes


def target(name, doc):
    """The next archive file for a document; refuses if it already exists."""
    previous = doc.get("previous_doc")
    number = 1
    if previous is not None:
        match = re.fullmatch(rf"docs/archive/{name}-(\d{{3,}})\.json", str(previous))
        if not match:
            raise Refusal(f"docs/{name}.json: previous_doc {previous!r} is not docs/archive/{name}-NNN.json")
        number = int(match.group(1)) + 1
    path = f"docs/archive/{name}-{number:03d}.json"
    if os.path.exists(path):
        raise Refusal(f"{path} already exists")
    return path


def stamp(doc, state, previous):
    """Put doc_state and previous_doc right after the schema field, or first."""
    fields = {"doc_state": state, "previous_doc": previous}
    anchor = next((k for k in SCHEMA_KEYS if k in doc), None)
    out = {} if anchor else dict(fields)
    for key, value in doc.items():
        if key not in fields:
            out[key] = value
        if key == anchor:
            out.update(fields)
    return out


def split(doc, moves, archive_path):
    """Return (current, archive) documents, both keeping the original order."""
    picks = {path: set(keys) for path, keys in moves}

    def walk(node, path):
        current, archive = {}, {}
        for key, value in node.items():
            here = path + (key,)
            if here in picks:
                chosen = picks[here]
                if isinstance(value, dict):
                    archive[key] = {k: v for k, v in value.items() if k in chosen}
                    current[key] = {k: v for k, v in value.items() if k not in chosen}
                else:
                    archive[key] = [x for i, x in enumerate(value) if i in chosen]
                    current[key] = [x for i, x in enumerate(value) if i not in chosen]
            elif any(p[:len(here)] == here for p in picks):
                current[key], archive[key] = walk(value, here)
            else:
                current[key] = value
        return current, archive

    current, archive = walk(doc, ())
    schema = {k: doc[k] for k in SCHEMA_KEYS if k in doc}
    return (stamp(current, "current", archive_path),
            stamp({**schema, **archive}, "archived", doc.get("previous_doc")))


def canon(item):
    return json.dumps(item, sort_keys=True)


def verify(original, current, archive, moves):
    """True if every original item is in exactly one of the two files and nothing else changed."""
    for path, _ in moves:
        a, b, c = get(original, path), get(current, path), get(archive, path)
        if isinstance(a, dict):
            if not isinstance(b, dict) or not isinstance(c, dict) or b.keys() & c.keys() or {**b, **c} != a:
                return False
        elif sorted(map(canon, (b or []) + (c or []))) != sorted(map(canon, a)):
            return False
        get(current, path[:-1])[path[-1]] = a
    fields = ("doc_state", "previous_doc")
    return ({k: v for k, v in current.items() if k not in fields}
            == {k: v for k, v in original.items() if k not in fields})


def main(argv):
    if argv not in ([], ["--write"]):
        print("usage: archive.py [--write]", file=sys.stderr)
        return 2
    write = argv == ["--write"]
    try:
        try:
            os.chdir(git("rev-parse", "--show-toplevel"))
        except (OSError, subprocess.CalledProcessError):
            raise Refusal("not inside a git repository")
        paths = {name: f"docs/{name}.json" for name in DOCS}
        if write and git("status", "--porcelain", "--", *paths.values()):
            raise Refusal("docs/context.json or docs/requirements.json has uncommitted changes; commit them first")
        docs = {name: load(path) for name, path in paths.items()}
        moves, notes = plan(docs["context"], docs["requirements"])
        for note in notes:
            print(note)
        if not any(moves.values()):
            print("Nothing to move.")
            return 0
        targets = {name: target(name, docs[name]) for name in DOCS if moves[name]}
        for name, archive_path in targets.items():
            print(f"{paths[name]} -> {archive_path}")
            for path, picks in moves[name]:
                print(f"  {'.'.join(path)}: {len(picks)}")
        if not write:
            print("Dry run; nothing written. Run with --write to split.")
            return 0
        splits = {name: split(docs[name], moves[name], targets[name]) for name in targets}
        os.makedirs("docs/archive", exist_ok=True)
        for name, (_, archive) in splits.items():
            dump(targets[name], archive, "x")
        for name, (current, _) in splits.items():
            dump(paths[name], current, "w")
        for name in splits:
            if not verify(docs[name], load(paths[name]), load(targets[name]), moves[name]):
                raise Refusal(f"check failed: {paths[name]} and {targets[name]} do not hold every original "
                              "item exactly once; restore docs/*.json with git and delete the new archive files")
        print("Done. Review with git diff and commit.")
        return 0
    except Refusal as e:
        print(f"archive.py: {e}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
