---
description: "Save standing operator rules from this agent's own memory into docs/bridge-memory.json"
---

You are saving what your own memory holds about this project — operator rulings, conventions and lessons — into `docs/bridge-memory.json`, the shared rules file every agent and every machine reads. The file holds the rules in force now, not a log; git history is its log, and `docs/decisions.md` stays the decision history. Your memory can be stale, so it never silently overrules a recorded rule.

## Steps

1. **Read.** Your own memory for this project (whatever your harness keeps outside the repository), `docs/bridge-memory.json` if present, and `docs/decisions.md` (its `D-CONV-n` lines and later dated decisions).
2. **Add what is new.** Add each item that is important and not yet recorded in either file. Compare by meaning, not wording. Give each new rule the next id: one past the highest `D-CONV-n` in `docs/bridge-memory.json` or `docs/decisions.md`. Ids are never reused; a removed rule's number still counts (`git log -p -- docs/bridge-memory.json` shows it). Write each rule as one neutral, self-contained line, with `since` set to the date the ruling was made (`YYYY-MM-DD`).
3. **Propose, don't overrule.** When your memory says a recorded rule changed or no longer holds, propose the change or removal in your report and wait. Apply it only after the operator explicitly confirms, then commit again. Never edit or delete a recorded rule on your own.
4. **Leave out** secrets, credentials, personal data, characterizations of people and machine-specific notes (local paths, installed tools).
5. **Record and report.** Update only your own `last_run` entry, keyed `claude-code`: today's date, the base commit (short hash of HEAD before your commit), how many rules you added and how many changes you proposed. Never touch another harness's entry. Commit `docs/bridge-memory.json` alone (never push), then report what you added, proposed and skipped, and why.

## File Shape

If `docs/bridge-memory.json` does not exist, create it with this shape: JSON, 2-space indent, trailing newline. A run with nothing to add still records its `last_run`, so the next agent sees it.

```json
{
  "schema": "bridge.memory.v1",
  "rules": [
    {"id": "D-CONV-1", "since": "YYYY-MM-DD", "rule": "One line, neutral, self-contained."}
  ],
  "last_run": {
    "claude-code": {"date": "YYYY-MM-DD", "base": "<short commit>", "added": 1, "proposed": 0}
  }
}
```

`rules` holds current rules only. `last_run` holds one entry per harness (`claude-code`, `codex`, ...).

## Required Closing (do not omit)

Your response MUST end with a HUMAN: block. Use this format:

```
HUMAN:
1. Review the commit (git show HEAD) — are the added rules accurate, neutral and free of personal or machine-specific detail?
2. Decide each proposed change or removal: confirm, reword or reject — nothing proposed is applied until you confirm
3. Run bridge-persist in your other agents so their memory is saved too; push when ready
```

$ARGUMENTS
