# .ai-local — personal harness extensions

This directory is yours. It is gitignored except for this README, it stays on
your machine, and nothing in it ships.

## Convention

- Put each personal setup under `.ai-local/<name>/` in whatever shape your tool
  wants: its own `AGENTS.md`, `CLAUDE.md`, `.claude/`, `.agents/`, `.codex/`, notes.
- Codex discovers `AGENTS.md` and trusted `.codex/` configuration layers from
  the project root down to your working directory. A nested setup can load when
  you work inside it; it is outside the search path in a repo-root session.
  Claude Code reads the root `.claude/` directory.
- To select personal guidance from the repo root, create `.ai-local/index.md`
  (per machine, gitignored); an agent follows the root entrypoint pointer:

```markdown
# Local harness extensions

Additive only. Nothing here overrides AGENTS.md, docs/requirements.json,
docs/context.json, or docs/decisions.md. Read a row only when its trigger matches.

| Path | Harness | Read when |
|---|---|---|
| `.ai-local/codex-desktop/` | codex | Codex Desktop sessions; personal review skills |
```

Three columns: Path, Harness, Read when. If it needs a fourth, it is doing too much.

## The one rule: additive only

Add skills, notes, routing, prompts. Do not redefine the contract, redirect a
canonical artifact (`docs/requirements.json`, `docs/context.json`,
`docs/decisions.md`), or change what an acceptance test means. Anything worth
sharing graduates into the BRIDGE pack through a reviewed change; it is never
shared by tracking `.ai-local/`.

## Housekeeping

- `.gitignore` carries `.ai-local/*` and `!.ai-local/README.md`; only this README is tracked.
- `bridge.sh update` never touches anything under `.ai-local/` (this README is add-only).
