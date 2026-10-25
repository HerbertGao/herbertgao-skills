---
name: journey-review
description: Reviews complete user journeys against product goals by driving the real application, checking business postconditions, and distinguishing failures from environment blocks. Use for end-to-end workflow review, cross-step product bugs, recovery paths, and UI or API journeys that static tests miss. Don't use for source-only code review, architecture selection, or validating implementation merely against its own tests.
---

# Journey Review

Determine whether a user can complete a real task and reach the required business state. Treat the running product and its externally observable state as the evidence, not the persuasiveness of its implementation or tests.

The review phase is independent and leaves the repository unchanged. Do not edit product code, configuration, fixtures, or data except for authorized test-environment setup. Use `review-loop` for artifact or code review and `council` for open architecture decisions.

## Non-negotiables

- Judge the product against the user goal and product contract. Existing code, current UI flow, tests, and CI status describe the implementation; none defines what the product ought to do.
- Execute through the interfaces available to the chosen actor. Do not substitute source inspection, mocks, direct database writes, or a unit test for the journey.
- Require a visible read-back or independent business query for every write. A form submission, success toast, HTTP 2xx, or green test is not proof of the final state.
- Separate `FAIL` from `BLOCKED`: an observed product defect is a failure; an unavailable account, environment, or verification route is a block.
- The review phase is read-only; remediation is a separate phase. Make no fixes unless the user explicitly requests them after the review; a later fix requires a new regression run.

## Procedure

### 1. Establish the product contract

1. Read the smallest sufficient set of user requirements, product documentation, API contracts, acceptance criteria, and existing test cases.
2. Rank truth sources as follows:
   - explicit user requirements and accepted product decisions;
   - product specifications, contracts, and acceptance criteria;
   - observed UI copy and current behavior, which can establish intent or self-consistency but not product correctness.
3. Use existing tests and CI only as supporting implementation evidence. Never promote their assertions into product requirements without a product source.
4. Record contradictions or missing requirements. Ask for the decision when it changes the journey or expected result; otherwise state the narrowest assumption and mark it as an assumption.
5. Write a task card before execution:

```text
Review: <name and scope>
Actor: <one role, tenant, and permission set>
Goal: <one user task>
Start state: <known initial state>
Environment: <non-production target and build/version>
Required postconditions: <atomic checks or none-yet>
Allowed setup: <accounts, fixtures, and data resets>
Out of scope: <other actors and unrelated journeys>
Stop rules: <production, irreversible actions, secrets, or missing authorization>
```

6. Define one primary actor per journey. Do not hide a second role, tenant, or permission set inside the same happy path; create a separate journey when needed.

### 2. Make postconditions falsifiable

1. Read assets/expected-output.md and turn the goal into atomic business postconditions before observing the implementation path.
2. Include the final entity or workflow state, important field values, ownership or tenant, counts or side effects, and forbidden side effects when relevant.
3. Specify how each condition can be observed: a UI read-back, public API query, authorized read-only business query, exported artifact, or another externally meaningful result.
4. For asynchronous work, define the observable completion condition and a bounded wait. Distinguish accepted, processing, completed, and failed states. Use a product completion deadline when one exists: exceeding it is `FAIL`. If the bounded review wait ends without a final result before that deadline, or no product deadline exists, mark it `BLOCKED` with reason `inconclusive asynchronous result`; never guess `FAIL` or `PASS`.
5. If no postcondition can be verified, do not infer success from navigation. Record the affected journey as `JOURNEY-BLOCKED` with reason `missing business query`.

### 3. Prepare real execution

1. Start or locate the application using the repository's documented development or test path. Use a non-production environment and authorized test identities.
2. Seed or reset only the minimum data needed for the start state. Never manipulate production data or perform irreversible external actions without explicit authorization.
3. Prefer an independent browser or API session with clean storage and known fixtures. Record the build, environment, actor, and start state so another reviewer can reproduce the result.
4. Derive a small set of journeys from the task card rather than from the current UI:
   - the primary goal;
   - each requirement-critical branch or permission boundary;
   - relevant interruption, rejection, retry, duplicate submission, or recovery paths.
5. Keep scope proportionate. Select the few journeys that cover the requested goal and its material risks; do not claim exhaustive coverage.
6. If the environment cannot be run safely, stop execution and report `JOURNEY-BLOCKED`. Do not replace execution with static reasoning.

### 4. Execute and preserve evidence

1. Give a fresh Journeyman only the task card, its completed expected-output worksheets, allowed environment, and stop rules. Do not reveal implementation details, suspected defects, or other reviewers' conclusions before the run.
2. Operate the normal UI or public API as the actor. Follow the task, not a script derived from internal function names.
3. After every material step, record:

```text
Evidence: <E#>
Journey / step: <name and number>
Action: <actor operation>
Expected: <task-card expectation>
Observed: <actual visible or queried result>
Artifact: <screenshot, response, log, or query reference>
Time / request ID: <when available>
```

4. Probe after every write. Read the resulting business state independently and compare exact required values, not merely presence or a generic success indicator.
5. Preserve negative evidence too: empty results, rejected operations, stale views, retries, and differences between immediate and refreshed reads.
6. Classify an environment timeout or missing capability as blocked only when the product itself is not implicated. A reproducible product hang, impossible continuation, or incorrect result is a failure.
7. Redact credentials, tokens, personal data, and unrelated customer data from evidence. Keep enough detail to reproduce the observation.

### 5. Analyze failures and adjacent risks

1. Read references/failure-catalog.md after collecting observations. Classify confirmed findings; do not force observations into every category.
2. Trace a confirmed failure across the whole chain: trigger, missing or incorrect transition, visible consequence, business-state consequence, and final postcondition.
3. Inspect implementation only after a failure is observed, and only to locate or explain it. Never reverse an observed failure because the code appears reasonable.
4. Consolidate multiple symptoms with one root cause into one finding, listing every affected journey and piece of evidence.
5. Assign severity using the catalog. Distinguish task-blocking defects from friction and optional improvements; a P2 or P3 observation does not automatically fail an otherwise successful journey.
6. Mark speculation as `Not executed` or `Blocked`, never as a confirmed failure or pass.

### 6. Apply four review roles

Use dedicated workers when the host supports them. Otherwise, perform the roles sequentially and disclose the loss of independence. Do not make staffing limitations a reason to fabricate consensus.

- **Journeyman:** Execute the goal from a fresh context and report actions, observations, and evidence without rationalizing defects. Keep this role isolated from implementation and other analysis until its run is complete.
- **Failure Analyst:** Audit evidence for broken transitions and false-success claims. Inspect code only to localize confirmed failures.
- **Product Challenger:** Compare the journey with the user goal. Look for technically successful flows that require unexplained knowledge, unreasonable workarounds, or contradict the product contract.
- **Recovery Challenger:** Exercise or assess relevant refresh, back, retry, duplicate, rejection, interruption, and permission paths. Execute any new path under the same evidence rules.

Independence and severity are reviewer judgments, not mechanical certifications. State when roles share a context or when a risk was only analyzed rather than executed.

### 7. Validate the result

1. Reconcile every required postcondition with a specific evidence ID. Mark it `PASS`, `FAIL`, or `BLOCKED`; absence of evidence is not `PASS`.
2. Assign one terminal state to each selected journey:
   - `JOURNEY-FAIL` when the task cannot be completed, a required postcondition is false, or a P0/P1 defect invalidates the journey;
   - `JOURNEY-BLOCKED` when execution or required verification could not occur for one of the allowed reasons below;
   - `JOURNEY-PASS` only when the task completed and every required postcondition has passing evidence.
3. Use only these block reasons: `missing test account`, `missing environment`, `missing business query`, `requires real payment`, `missing authorization`, `missing product contract`, or `inconclusive asynchronous result`.
4. Set the review result to `JOURNEY-FAIL` if any selected journey fails. Otherwise set it to `JOURNEY-BLOCKED` if any selected journey is blocked. Emit `JOURNEY-PASS` only when every selected journey passes.
5. Read assets/report-template.md and complete every applicable field. Keep passed paths, failures, blocks, unexecuted risks, and assumptions separate.
6. End the complete review with exactly one overall terminal token. Do not emit a bare token without the evidence report.

## Optional fix regression

Only after an explicit remediation request, verify both the original failing journey and each adjacent journey that passed before the change. If the original path passes but a previously passing path fails, end the regression review with `JOURNEY-FAIL`. Do not reuse old observations as new evidence.

## Error handling

- **No runnable environment:** Record setup attempts and report `JOURNEY-BLOCKED` with reason `missing environment`.
- **No usable identity or permission:** Report `JOURNEY-BLOCKED` with reason `missing test account` or `missing authorization` as applicable.
- **No independent read-back:** Report `JOURNEY-BLOCKED` with reason `missing business query` for the affected write; do not call the write successful.
- **Real payment or irreversible external effect required:** Stop before the effect unless the user has explicitly authorized a safe test mechanism. Report `JOURNEY-BLOCKED` with reason `requires real payment` for payment; otherwise use `missing authorization`.
- **Conflicting requirements:** Do not invent a winner. Request the decision or report the affected assertion as an assumption and the journey as `JOURNEY-BLOCKED` with reason `missing product contract` when no falsifiable expectation exists.
- **No independent workers:** Run the roles sequentially, preserve the Journeyman's observation-first order, and disclose reduced independence without changing the terminal-state rules.
