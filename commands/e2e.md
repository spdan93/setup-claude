---
name: e2e
description: Run a browser E2E test suite via a browser-automation agent and generate a markdown evidence report
---

# E2E Test Command

Run a browser-driven E2E test suite against a running dev server, using a browser-automation agent, and generate a markdown evidence report at the end.

> **Note**: Write the report, comments, and status messages in the project's dominant language (detect from repo docs/commits; default English if unclear).

---

## When to use

- Validate the end-to-end behavior of a recently implemented feature before merge.
- Reproduce a bug in a controlled environment and produce an audit-trail evidence file.
- Visual/regression smoke-test (mobile/desktop) after UX changes.

**Do not use** for:
- Testing isolated logic (use the project's unit-test runner directly)
- Purely client-side flows without visual rendering (use a unit test)

---

## Prerequisites (user's responsibility)

Before calling `/e2e`, the user must ensure the target app is running. The command **does not start servers** and **does not perform any authentication/login** — it only checks that the target responds. If it doesn't, it returns a clear error with instructions.

Project-specific startup (how to run the dev server, which port, whether a manual login is required) varies per project. Ask the user for the target URL if it isn't provided as an argument.

---

## Arguments

```
/e2e <feature-name> [--url=<base-url>] [--final]
```

| Argument | Required | Description |
|---|---|---|
| `<feature-name>` | yes | slug of what is being tested (e.g. `login-flow`, `consent-banner`, `checkout`) |
| `--url` | no | base URL of the running dev server (e.g. `http://localhost:3000`). If omitted, ask the user — never hardcode a port. |
| `--final` | no | when present, save the report to `docs/test-evidence/` (tracked in git). Without the flag, save to `.test-evidence-local/` (gitignored) — useful for fast iteration without inflating history. |

**Example**: `/e2e login-flow --url=http://localhost:3000 --final`

---

## Command flow

### 1. Validate prerequisites

Determine the base URL (from `--url` or by asking the user). Then verify the server is up **before** spawning the agent. If the check fails, **stop and report to the user**:

```bash
curl -s -o /dev/null -w "%{http_code}" <base-url>/ --max-time 3
# Expect: 200 (or another success/redirect code the app uses)
```

If it errors, ask the user to start the dev server (and complete any required manual login) and re-run.

### 2. Optional project-specific setup hooks

Some projects need setup before E2E runs (e.g. a test-mode flag, analytics/consent interceptor, seeded data, a fixture file edited per scenario). These are **project-specific and optional**. Ask the user whether any such hooks are needed and capture them as free text to inject into the agent prompt. If none, skip.

If the user names a **fixture file** that scenarios will modify, back it up first so it can be restored later (see steps 3 and 7).

### 3. Backup any named fixture file

If the user named a fixture file to be modified during testing, back it up and remember the backup path for a guaranteed restore at the end:

```bash
cp "<fixture-file>" "/tmp/e2e-fixture-backup-$(date +%s).bak"
```

### 4. Interactively collect the test plan

Ask the user (via `AskUserQuestion`):

- **Which scenarios** to test? (free text — the user describes them at a high level)
- **Per-scenario fixture/setup changes** needed? (list of changes, or "none")
- **Viewports**: Desktop, Mobile, or Both? (default: Both)

From the answers, build a **scenario × viewport matrix** that will drive the final report.

### 5. Spawn the browser agent with a structured prompt

Use the browser-automation capability available in the environment. Prefer:
- the `playwright-e2e-testing` skill for guidance/patterns, and/or
- a browser-automation agent via the `Agent`/Task tool (a browser-user subagent), or the Playwright MCP browser tools if available.

Pass a prompt built from the template below (substitute placeholders between `{{}}`).

**Prompt template**:

```
Test the feature `{{feature-name}}` at `{{base_url}}`.

## Required setup before any scenario

{{project_specific_setup_hooks_from_step_2_or_"none"}}

## Viewports

- desktop: 1280×800, no mobile emulation
- mobile: 390×844, deviceScaleFactor 3, mobile user-agent, touch events enabled

## Scenarios to execute

{{scenario_matrix_built_from_user_answers}}

## State cleanup between scenarios (if applicable)

Clear cookies / localStorage between scenarios when the flow requires a clean state.

## REQUIRED response format

For EACH scenario in EACH viewport, return:

```yaml
scenario: "{{name}}"
viewport: "{{desktop|mobile}}"
status: PASS | FAIL | SKIP
checks:
  - check: "elementPresent"
    expected: true
    actual: true
    status: PASS
  - check: "ctaDisabled before action"
    expected: true
    actual: true
    status: PASS
observations: "any surprise, bug, or unexpected behavior"
duration_ms: 4500
screenshots:
  - { moment: "form-rendered", description: "submit button visible below the form" }
```

Do NOT improvise different formats — the final report is generated by parsing this.
```

### 6. Capture and parse the agent response

When the agent finishes, it returns a report in the yaml-like format above. Parse each scenario and build the internal structure used to generate the markdown.

If the agent stalls (timeout, error, malformed output), report the real state and mark remaining scenarios as `SKIP`.

### 7. Restore any backed-up fixture (always)

Even if some scenario fails, **guarantee** that any fixture file backed up in step 3 is restored:

```bash
cp "/tmp/e2e-fixture-backup-<timestamp>.bak" "<fixture-file>"
```

Treat this as a `try/finally` in the command flow — restore runs whether or not the run succeeded.

### 8. Generate the report

Create the evidence file at the appropriate path:

```
docs/test-evidence/{{feature-name}}-{{YYYY-MM-DD-HHmm}}.md    # if --final
.test-evidence-local/{{feature-name}}-{{YYYY-MM-DD-HHmm}}.md  # otherwise
```

**Report structure**:

```markdown
# E2E Test Evidence — {{feature-name}}

**Target URL**: {{base_url}}
**Executed at**: {{YYYY-MM-DD HH:mm:ss}}
**Branch**: {{git rev-parse --abbrev-ref HEAD}}
**Commit**: {{git rev-parse --short HEAD}}
**Command**: `/e2e {{feature-name}} {{--url}} {{--final?}}`
**Total duration**: {{time}}

## Executive Summary

| Metric | Value |
|---|---|
| Scenarios executed | {{N}} |
| PASS | {{N}} |
| FAIL | {{N}} |
| SKIP | {{N}} |
| Viewports covered | {{list}} |

## Results by scenario

### Scenario 1 — {{name}}

**Viewport**: {{desktop|mobile}}
**Status**: ✅ PASS / ❌ FAIL / ⏭ SKIP
**Duration**: {{ms}}

#### Setup
{{what was modified in the fixture or initial state}}

#### Assertions
| Check | Expected | Actual | Status |
|---|---|---|---|
| ... | ... | ... | ✅/❌ |

#### Observations
{{surprises, bugs found, described screenshots}}

---

(repeat per scenario)

## Bugs / surprises found

- ...

## Environment

- Target URL: {{base_url}}
- Browser: {{driver used}}
- Desktop user-agent: ...
- Mobile user-agent: ...
- Dev server status: healthy

## How to reproduce

1. {{exact steps to run the failing scenario locally, if any}}
```

### 9. Output to the user

Report to the user:
- Path of the generated report
- Overall status (X PASS / Y FAIL / Z SKIP)
- If `--final`: remind that the file is tracked and should be included in the next commit
- If there are FAILs: list each failing scenario with its main reason

---

## First-time setup (once per project)

The first time `/e2e` is called in a new project, create:

### `.gitignore` entry

```bash
# Add if not present
echo ".test-evidence-local/" >> .gitignore
```

### `docs/test-evidence/INDEX.md`

```markdown
# E2E Test Evidence — Index

History of E2E test runs via `/e2e`.

Each `{feature-name}-{timestamp}.md` file is a complete run with:
- Scenario × viewport matrix
- Expected vs actual assertions
- Surprises/bugs found
- Total time + reproduction steps

## By feature

(auto-populated as new reports are generated — list the latest 20)
```

After creating a new evidence file, update `INDEX.md` by adding a line:

```markdown
- 2026-05-12 14:30 — [login-flow](login-flow-2026-05-12-1430.md) — 4 scenarios PASS, 0 FAIL
```

---

## Important rules

1. **NEVER modify a fixture file without a backup**: restore at the end is mandatory even on failure
2. **NEVER log credentials in the report**: tokens, real emails, secrets — use dummy data only
3. **NEVER assume the server is running**: always validate via `curl` before spawning the agent
4. **NEVER hardcode ports/URLs**: take the base URL from `--url` or ask the user
5. **Report language**: follow the project's dominant language convention
6. **Real timings**: measure each scenario's duration to detect performance regressions

---

## Final checklist

Before returning to the user:

- [ ] Target server verified healthy via `curl`
- [ ] Fixture file backed up (if applicable)
- [ ] Browser agent invoked with the structured prompt
- [ ] Agent response parsed
- [ ] Report generated at the correct path (`--final` or local)
- [ ] Fixture file restored from backup (if applicable)
- [ ] `INDEX.md` updated (if `--final`)
- [ ] Output to the user with overall status and file path
- [ ] If `--final` AND all PASS: remind the user to commit the evidence file

---

## Known limitations

1. **Does not automate logins** — flows requiring authentication need the user to log in manually before the run
2. **Screenshot fidelity depends on the browser driver** — some drivers only describe visual state rather than capturing real images
3. **No pixel-perfect regression** — visual comparison is descriptive, not an image diff
4. **Execution times may be approximate** — depending on the driver, timings can be estimated from the overall invocation
