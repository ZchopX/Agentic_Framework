# Evidence and Confidence

## Contents
- Reproduction kinds, strongest first
- Red-capable check properties
- Confidence levels
- Hard-to-reproduce bugs: accepted evidence
- Testing a fix in isolation
- The removal check
- Pre-existing or introduced

## Reproduction kinds, strongest first

Failing automated test; runnable script or command; deterministic scripted manual steps; captured trace or log replay; user recording or screenshots with steps; description only.

## Red-capable check properties

Fails now for the stated reason (compare the failure message with the symptom); deterministic (run twice); fast (ideally under a minute); agent-runnable. If a human must be in the loop, write exact numbered steps for the user to run and the observation to report back.

## Confidence levels

| Level | Meaning | Verdicts allowed |
|---|---|---|
| Verified | Fail → pass (→ fail → pass) was observed | All |
| Plausible | Concrete evidence (logs, trace, code path) but no executed loop | All except plain `APPROVE` |
| Speculative | Reasoning only | `NEEDS EVIDENCE` (or `NOT A BUG` if the specified behavior is shown) |

## Hard-to-reproduce bugs: accepted evidence

- Intermittent: run in a loop N times, seed randomness, add temporary logging in a scratch copy, stress concurrency.
- Prod-only: logs, metrics, request IDs, a config or environment diff between prod and local.
- Perceptual UX ("feels slow", "feels wrong"): a step list plus measured timings (browser performance panel, `performance.now()`, `time` for CLIs) compared against the response-time limits, or a screen recording.

## Testing a fix in isolation

- Preferred: `git worktree add <temp-dir> HEAD`, apply the fix there, run the check, then `git worktree remove <temp-dir>`.
- Alternative: copy the project to a temp dir.
- Never use `git stash`, `git reset`, or `git checkout -- <file>` on the user's tree.
- If the user's fix exists only as uncommitted changes, run `git diff > <temp>/fix.patch`, then `git apply` inside the worktree.

## The removal check (Agans)

Apply the fix → pass; take it out → fail; put it back → pass. If removing the fix does not bring the failure back, the fix is not what fixed it.

## Pre-existing or introduced

Use `git blame` or `git log -L <start>,<end>:<file>` on the implicated lines, and `git log --oneline -- <file>` for recent changes. When a scripted reproduction exists and history is long, use `git bisect run <check>` (in a worktree).
