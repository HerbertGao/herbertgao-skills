#!/usr/bin/env python3
"""Check every SKILL.md against contracts/format.json.

Universal skill copies stay self-contained; packaged plugins may ship pinned
references. Canonical strings remain in every SKILL.md, making their spelling
checkable instead of relying on a prose reviewer to notice drift.

Run: scripts/check-format.py            exit 1 on any failure
     scripts/check-format.py --self-test   prove the checks can actually fail
"""
import glob
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CONTRACT = os.path.join(ROOT, "contracts", "format.json")
CATALOG = os.path.expanduser(os.environ.get("AGENCY_AGENTS", "~/.agency-agents"))

# Every field is declared, always: an absent key and a misspelled one look identical,
# so "no rule here" has to be said out loud as [] rather than by silence.
FIELDS = {"files", "tiers", "marker_prefix", "marker_forms", "required_verbatim",
          "catalog_paths", "echo_labels", "tokens", "exhaustive", "fenced_must_contain"}

# Same discipline at the top level: a typo'd key must not silently delete its own rule.
TOP_LEVEL = {"$comment", "forbidden_everywhere", "skills", "consumer_surfaces", "catalog", "families"}

# Deliberately looser than the literal it checks against: the malformed spellings are
# the whole point, so the regex has to SEE them before the assertion can reject them.
# Bounded to one line — a marker never spans one, and an unbounded run swallows the
# evaluator's own bracket-less prefix literal and everything after it.
MARKER_RE = re.compile(r"[\[［]\s*[Ee][Mm][Bb][Ee]?[Dd]+[Ee]?[Dd]?[^\]］\n]*[\]］]")  # embeded / ［embedded］ / Embedded…
LOCAL_PATH_RE = re.compile(r"\[local: ([A-Za-z0-9._/-]+\.md)\]")
# The ladder's own backtick paths — the table the agent actually reads to resolve a lane.
SPEC_PATH_RE = re.compile(r"`([a-z0-9-]+/[a-z0-9./-]+\.md)`")
COUNCIL_DISPATCH_KINDS = ("seat", "re-dispatch", "retry", "cross-exam", "DA",
                          "DA-final", "tie-breaker", "label", "audit")
COUNCIL_AUDITOR_REF = "council/skills/council/references/auditor-enumerator.md"
COUNCIL_AUDITOR_FIXTURE = "evals/council/fixtures/claude-auditor/session.jsonl"
COUNCIL_CLAUDE_SKILL = "council/skills/council/SKILL.md"


def _unique_json_object(pairs):
    value = {}
    for key, item in pairs:
        if key in value:
            raise ValueError(f"duplicate JSON key {key!r}")
        value[key] = item
    return value


def loads_json_unique(body: str):
    return json.loads(body, object_pairs_hook=_unique_json_object)


def load_json_unique(path: str):
    with open(path, encoding="utf-8") as fh:
        return json.load(fh, object_pairs_hook=_unique_json_object)


def _select_required_scope(body: str, selector: str):
    """Select the structural region in which a load-bearing literal must live."""
    if selector == "text":
        return body, None
    if selector.startswith("before-section-prefix:"):
        prefix = re.escape(selector.removeprefix("before-section-prefix:"))
        headings = list(re.finditer(rf"^##\s+{prefix}[^\n]*$", body, re.M))
        if len(headings) != 1:
            return None, f"scope {selector!r} resolved {len(headings)} times, expected exactly one"
        return body[:headings[0].start()], None
    fenced = selector.startswith("fences-in-section-prefix:")
    if fenced or selector.startswith("section-prefix:"):
        marker = "fences-in-section-prefix:" if fenced else "section-prefix:"
        prefix = re.escape(selector.removeprefix(marker))
        headings = list(re.finditer(rf"^##\s+{prefix}[^\n]*$", body, re.M))
        if len(headings) != 1:
            return None, f"scope {selector!r} resolved {len(headings)} times, expected exactly one"
        start = headings[0].end()
        following = re.search(r"^##\s+", body[start:], re.M)
        section = body[start:start + following.start()] if following else body[start:]
        if not fenced:
            return section, None
        blocks = re.findall(r"```[A-Za-z0-9]*\n(.*?)```", section, re.S)
        if not blocks:
            return None, f"scope {selector!r} contains no fenced block"
        return "\n".join(blocks), None
    return None, f"unknown required-literal scope {selector!r}"


def check(contract: dict, files: dict, tracked) -> list:
    """contract + file bodies + the catalog's tracked paths -> failures.

    Pure, so --self-test can drive it with synthetic specs. `tracked` is None when no
    catalog is available; main() decides whether that absence is fatal.
    """
    fails = []

    def fail(msg):
        fails.append(msg)

    # 越权搭配是一类不是一张拼写表：正则扫描前剥掉 non-certif*/unaudited，
    # 让正规 token『ADVISORY (…; unaudited)』与『non-certifying ADVISORY』不误伤。
    _strip_legit = re.compile(r"(?i)non-certif\w*|unaudited")
    for root in contract["forbidden_everywhere"]["files"]:
        for rel, body in files.items():
            if not (rel == root or rel.startswith(root + "/")):
                continue
            for p in contract["forbidden_everywhere"]["patterns"]:
                if p.lower() in body.lower():
                    fail(f"forbidden string {p!r} in {rel} — a removed behavior leaves no notice behind")
            stripped = _strip_legit.sub("", body)
            for rp in contract["forbidden_everywhere"].get("regex_patterns", []):
                if re.search(rp, stripped):
                    fail(f"forbidden collocation {rp!r} in {rel} — an escalating ADVISORY variant must not exist anywhere")

    for name, spec in contract["skills"].items():
        unknown = {k for k in spec if not k.startswith("$")} - FIELDS
        missing = FIELDS - set(spec)
        if unknown:
            fail(f"[{name}] unknown contract field(s) {sorted(unknown)} — a typo'd key is a rule nobody runs")
        if missing:
            fail(f"[{name}] contract field(s) not declared {sorted(missing)} — declare [] to mean 'none'")
        if unknown or missing:
            continue

        prefix = spec["marker_prefix"]
        for form in spec["marker_forms"]:
            if prefix and not form.startswith(prefix):
                fail(f"[{name}] marker form does not start with the evaluator's literal "
                     f"{prefix!r}: {form!r}")

        for rel in spec["files"]:
            body = files.get(rel)
            if body is None:
                fail(f"[{name}] contract lists a file that does not exist: {rel}")
                continue

            for form in spec["marker_forms"]:
                if form not in body:
                    fail(f"[{name}] {rel}: canonical marker form missing verbatim: {form!r}")
            for requirement in spec["required_verbatim"]:
                if isinstance(requirement, str):
                    literal, selected, expected = requirement, body, None
                elif isinstance(requirement, dict) and set(requirement) == {"literal", "selector", "count"} \
                        and isinstance(requirement["literal"], str) \
                        and isinstance(requirement["selector"], str) \
                        and isinstance(requirement["count"], int) and requirement["count"] > 0:
                    literal, expected = requirement["literal"], requirement["count"]
                    selected, err = _select_required_scope(body, requirement["selector"])
                    if err:
                        fail(f"[{name}] {rel}: {err}")
                        continue
                else:
                    fail(f"[{name}] {rel}: malformed required_verbatim entry {requirement!r}")
                    continue
                observed = selected.count(literal)
                if (expected is None and observed == 0) or (expected is not None and observed != expected):
                    scope = "" if isinstance(requirement, str) else f" in {requirement['selector']!r}"
                    want = "at least once" if expected is None else f"exactly {expected} time(s)"
                    fail(f"[{name}] {rel}: required string must appear {want}{scope}: {literal!r} "
                         f"(observed {observed})")
            for tier in spec["tiers"]:
                if tier not in body:
                    fail(f"[{name}] {rel}: tier name {tier!r} never appears")
            for label in spec["echo_labels"]:
                if label not in body:
                    fail(f"[{name}] {rel}: echo label missing verbatim: {label!r}")
            for tok in spec["tokens"]:
                if tok not in body:
                    fail(f"[{name}] {rel}: terminal token {tok!r} never appears")

            # A stray space, capital or backtick in a marker is a degrade cap that
            # silently stops firing — the failure this whole file exists to prevent.
            if prefix:
                for m in MARKER_RE.findall(body):
                    if not m.startswith(prefix) or "`" in m:
                        fail(f"[{name}] {rel}: marker {m!r} is not matchable by the "
                             f"evaluator's literal {prefix!r}")

            # "The string exists somewhere" is not "every spelling of it is legal": a
            # second, drifted copy of a token is a gate that greps for nothing.
            for rule in spec["exhaustive"]:
                allowed = set(rule["allowed"])
                for m in re.findall(rule["regex"], body):
                    if m not in allowed:
                        fail(f"[{name}] {rel}: {m!r} is not a defined form "
                             f"(allowed: {sorted(allowed)})")

            # A rule can be word-perfect in the prose and absent from the block the agent
            # actually copies — and then nobody ever emits it. Check the template itself.
            blocks = re.findall(r"```[A-Za-z0-9]*\n(.*?)```", body, re.S)
            for want in spec["fenced_must_contain"]:
                if not any(want in b for b in blocks):
                    fail(f"[{name}] {rel}: {want!r} appears nowhere inside a fenced block — "
                         f"the copied template does not carry it")

            # The spec's own path table must be the one the catalog check verifies. Checking
            # the contract's copy and never reconciling it with the spec's is how the lane
            # table becomes fiction again with every gate green.
            declared = set(spec["catalog_paths"].values())
            for p in set(SPEC_PATH_RE.findall(body)) | set(LOCAL_PATH_RE.findall(body)):
                if p not in declared:
                    fail(f"[{name}] {rel}: the ladder names {p!r}, which catalog_paths does not "
                         f"declare — nothing verifies it resolves")
            if tracked is not None:
                for p in LOCAL_PATH_RE.findall(body):
                    if p not in tracked:
                        fail(f"[{name}] {rel}: `[local: {p}]` names a path a fresh catalog "
                             f"checkout does not ship")

        if tracked is not None:
            for role, path in spec["catalog_paths"].items():
                if path not in tracked:
                    fail(f"[{name}] catalog path {path!r} for role {role!r} is not tracked in a "
                         f"fresh checkout — the lane would silently degrade to a stand-in")

    return fails


def check_twins(files: dict) -> list:
    """Every universal skill ships a byte-identical Codex copy.

    In bash this was a `for t in codex-plugins/*/skills/$n/SKILL.md` loop guarded by
    `[ -f "$t" ]` — an unmatched glob made the body never run, so a *missing* twin
    passed green. Fail closed: a twin that is absent is a twin that drifted.
    """
    fails = []
    for src in sorted(f for f in files if re.fullmatch(r"skills/[^/]+/SKILL\.md", f)):
        name = src.split("/")[1]
        twins = [f for f in files if re.fullmatch(rf"codex-plugins/[^/]+/skills/{re.escape(name)}/SKILL\.md", f)]
        if not twins:
            fails.append(f"{src} has no Codex twin under codex-plugins/*/skills/{name}/")
        for t in twins:
            if files[t] != files[src]:
                fails.append(f"twin drift: {t} is not a byte-copy of {src}")
    return fails


HOST_KEY = "subagent_type"   # the host's dispatch key: the one thing the neutral file never names


def check_claude_copies(files: dict) -> list:
    """The hand-maintained Claude copy must stay a Claude copy.

    `skills/<n>/` is platform-neutral; `<plugin>/skills/<n>/` is its Claude-specific
    sibling, written by hand and NOT a mirror. Nothing guarded that, so one blanket
    `cp skills/<n>/SKILL.md <plugin>/skills/<n>/SKILL.md` flattens the Claude copy
    into the neutral text — every `subagent_type`, `general-purpose`, `isolation:`
    silently gone — and the validator still says OK. (It happened, on 2026-07-14.)

    The predecessor of this check was a semantic parity diff whose allowed-divergence
    list was generated FROM the current diff: an answer key, green by construction.
    So these three assertions read the files, not a snapshot of them:
      1. the Claude copy is not a byte-copy of the neutral one — it exists because it differs;
      2. it names the host's dispatch key — a flatten removes it;
      3. the neutral one does not — the reverse flatten, and the whole point of it being neutral.
    """
    fails = []
    for src in sorted(f for f in files if re.fullmatch(r"skills/[^/]+/SKILL\.md", f)):
        name = src.split("/")[1]
        copies = [f for f in files
                  if re.fullmatch(rf"(?!codex-plugins)[^/]+/skills/{re.escape(name)}/SKILL\.md", f)]
        if not copies:
            fails.append(f"{src} has no Claude copy at <plugin>/skills/{name}/SKILL.md")
        if HOST_KEY in files[src]:
            fails.append(f"{src} names {HOST_KEY!r} — the neutral spec must not carry a host's dispatch key")
        for c in copies:
            if files[c] == files[src]:
                fails.append(f"{c} is a byte-copy of {src} — the Claude copy was flattened onto the neutral one")
            elif HOST_KEY not in files[c]:
                fails.append(f"{c} never names {HOST_KEY!r} — it is not dispatching on Claude Code")
    return fails


def check_council_header_parser(files: dict) -> list:
    """Exercise the Claude auditor's parser against the header agents must emit."""
    rel = COUNCIL_AUDITOR_REF
    body = files.get(rel)
    if body is None:
        return [f"{rel}: required auditor reference is missing"]
    found = re.search(r"^HEADER_RE=re\.compile\(r'(.+)'\)$", body, re.M)
    if found is None:
        return [f"{rel}: auditor reference has no extractable HEADER_RE"]
    try:
        pattern = re.compile(found.group(1))
    except re.error as err:
        return [f"{rel}: HEADER_RE does not compile: {err}"]
    expected_kinds = COUNCIL_DISPATCH_KINDS
    skill = files.get(COUNCIL_CLAUDE_SKILL)
    if skill is not None:
        template = re.search(r"kind: <([^>]+)> \| dispatch:", skill)
        if template is None:
            return [f"{COUNCIL_CLAUDE_SKILL}: dispatch template has no extractable kind set"]
        template_kinds = tuple(template.group(1).split("|"))
        if template_kinds != COUNCIL_DISPATCH_KINDS:
            return [f"{COUNCIL_CLAUDE_SKILL}: template kind set {template_kinds!r} differs from checker/parser contract"]
        expected_kinds = template_kinds
    for kind in expected_kinds:
        valid = ("council: choose a database | run: deadbeef | seat: /tmp/expert.md | round: 1 "
                 f"| kind: {kind} | dispatch: 1")
        parsed = pattern.fullmatch(valid)
        if parsed is None or parsed.groupdict().get("run") != "deadbeef" or \
                parsed.groupdict().get("kind") != kind or parsed.groupdict().get("k") != "1":
            return [f"{rel}: HEADER_RE rejects or mis-parses kind {kind!r}"]
    no_kind = ("council: choose a database | run: deadbeef | seat: /tmp/expert.md | round: 1 "
               "| dispatch: 1")
    if pattern.fullmatch(no_kind) or pattern.fullmatch(valid.replace("kind: audit", "kind: fork")):
        return [f"{rel}: HEADER_RE accepts a header with no kind"]
    return []


def _run_council_auditor_fixture(body: str, fixture: str):
    """Extract and run the shipped enumerator against one synthetic main log."""
    if body is None or not os.path.isfile(fixture):
        return None, "Claude auditor fixture or enumerator is missing"
    found = re.search(r"```bash\npython3 .*? <<'EOF'\n(.*?)\nEOF\n```", body, re.S)
    if found is None:
        return None, f"{COUNCIL_AUDITOR_REF}: fenced enumerator script is not extractable"
    code = found.group(1)
    needle = 'glob.glob(os.path.expanduser("~/.claude/projects/*/*.jsonl"))'
    if needle not in code:
        return None, f"{COUNCIL_AUDITOR_REF}: canonical log discovery expression is missing"
    code = code.replace(needle, "[sys.argv[3]]", 1)
    run = subprocess.run([sys.executable, "-c", code, "deadbeef", "9", fixture],
                         cwd=ROOT, text=True, capture_output=True)
    return run, None


def check_council_auditor_inflight(files: dict) -> list:
    """Exercise completed, failed, retried, tool-using and in-flight dispatches."""
    body = files.get(COUNCIL_AUDITOR_REF)
    fixture = os.path.join(ROOT, COUNCIL_AUDITOR_FIXTURE)
    run, err = _run_council_auditor_fixture(body, fixture)
    if err:
        return [err]
    if run.returncode != 0:
        return [f"Claude auditor in-flight fixture failed: {run.stderr.strip() or run.stdout.strip()}"]
    expected = (
        f"LOG\t{os.path.abspath(fixture)}",
        "PRE-RUN\t1\thistorical-use\t",
        "DISPATCH\t1\tseat\tseat\tNone\t",
        'TOOL\tseat-k1\trecord:1\tWrite\t{"file_path": "/tmp/council-workdir/note.md", "content": "evidence"}',
        'TOOL\tseat-k1\trecord:2\tmcp__deploy__production\t{"target": "staging"}',
        "FAILED\t2\tcross-exam\tcross-exam\tNone\t",
        "DISPATCH\t3\tretry\tcross-exam\t2\t",
        "DISPATCH\t4\tre-dispatch\tseat\t1\t",
        "FAILED\t5\tre-dispatch\tcross-exam\t3\t",
        "DISPATCH\t6\tretry\tcross-exam\t5\t",
        "FAILED\t8\taudit\taudit\tNone\t",
        "DISPATCH\t9\tretry\taudit\t8\t",
        "\tIN-FLIGHT\t",
    )
    if "UNVERIFIABLE" in run.stdout or any(item not in run.stdout for item in expected):
        return ["Claude auditor mishandles sidecar tools, failure/retry, or its in-flight audit retry"]
    return []


def check_council_auditor_sidecar_negatives(files: dict) -> list:
    """Prove zero and duplicate sidecars are both surfaced, never chosen arbitrarily."""
    body = files.get(COUNCIL_AUDITOR_REF)
    fixture_root = os.path.dirname(os.path.join(ROOT, COUNCIL_AUDITOR_FIXTURE))
    if body is None or not os.path.isdir(fixture_root):
        return ["Claude auditor sidecar-negative fixture or enumerator is missing"]
    with tempfile.TemporaryDirectory(prefix="council-auditor-") as tmp:
        missing = os.path.join(tmp, "missing")
        shutil.copytree(fixture_root, missing)
        os.unlink(os.path.join(missing, "worker", "subagents", "agent-seat1.jsonl"))
        run, err = _run_council_auditor_fixture(body, os.path.join(missing, "session.jsonl"))
        if err or run.returncode != 0 or "UNVERIFIABLE\tseat-k1\tno-sidecar\tseat1" not in run.stdout:
            return [err or "Claude auditor does not surface a missing completed-worker sidecar"]

        duplicate = os.path.join(tmp, "duplicate")
        shutil.copytree(fixture_root, duplicate)
        extra = os.path.join(duplicate, "second", "subagents")
        os.makedirs(extra)
        shutil.copy2(os.path.join(duplicate, "worker", "subagents", "agent-seat1.jsonl"), extra)
        run, err = _run_council_auditor_fixture(body, os.path.join(duplicate, "session.jsonl"))
        if err or run.returncode != 0 or \
                "UNVERIFIABLE\tseat-k1\tduplicate-sidecars:2\tseat1" not in run.stdout:
            return [err or "Claude auditor does not surface duplicate completed-worker sidecars"]

        descendant = os.path.join(tmp, "descendant")
        shutil.copytree(fixture_root, descendant)
        seat_sidecar = os.path.join(descendant, "worker", "subagents", "agent-seat1.jsonl")
        with open(seat_sidecar, "a", encoding="utf-8") as fh:
            fh.write('{"message":{"content":[{"type":"tool_use","name":"Agent","id":"child-use","input":{}}]}}\n')
        run, err = _run_council_auditor_fixture(body, os.path.join(descendant, "session.jsonl"))
        if err or run.returncode != 0 or "UNVERIFIABLE\tseat-k1\tdescendant-dispatch:child-use" not in run.stdout:
            return [err or "Claude auditor hides a descendant dispatch from a seat sidecar"]

        malformed = os.path.join(tmp, "malformed-sidecar")
        shutil.copytree(fixture_root, malformed)
        seat_sidecar = os.path.join(malformed, "worker", "subagents", "agent-seat1.jsonl")
        with open(seat_sidecar, encoding="utf-8") as fh:
            sidecar_body = fh.read()
        with open(seat_sidecar, "w", encoding="utf-8") as fh:
            fh.write('{"message":{"role":"assistant","content":{"type":"tool_use","name":"Write","id":"hidden-write","input":{}}}}\n')
            fh.write(sidecar_body.split("\n", 1)[1])
        run, err = _run_council_auditor_fixture(body, os.path.join(malformed, "session.jsonl"))
        observed = (run.stdout + run.stderr) if run else (err or "")
        if "malformed-schema:1" not in observed:
            return ["Claude auditor accepts a non-array sidecar message.content"]
    return []


def check_council_auditor_record_negatives(files: dict) -> list:
    """Mutation-check fail-closed JSONL identity and retry linkage."""
    body = files.get(COUNCIL_AUDITOR_REF)
    fixture_root = os.path.dirname(os.path.join(ROOT, COUNCIL_AUDITOR_FIXTURE))
    if body is None or not os.path.isdir(fixture_root):
        return ["Claude auditor record-negative fixture or enumerator is missing"]
    with open(os.path.join(fixture_root, "session.jsonl"), encoding="utf-8") as fh:
        original = fh.read()
    lines = original.splitlines()
    pick = lambda needle: next(line for line in lines if needle in line)
    duplicate = original.replace(
        original.splitlines()[3],
        original.splitlines()[3] + "\n" + original.splitlines()[3].replace("dispatch: 1", "dispatch: 4"), 1)
    seat_result = pick('"tool_use_id":"seat-use"')
    duplicate_result = original.replace(seat_result, seat_result + "\n" + seat_result, 1)
    failed_audit = pick('"id":"failed-audit-use"')
    second_retry = ('{"message":{"content":[{"type":"tool_use","name":"Agent","id":"seat-retry2-use",'
                    '"input":{"prompt":"council: choose a database | run: deadbeef | seat: /tmp/expert.md '
                    '| round: 2 | kind: retry | dispatch: 4\\nretry-for: 2","subagent_type":"Explore"}}]}}')
    duplicate_retry = original.replace(failed_audit, second_retry + "\n" + failed_audit, 1)
    failed_seat_result = pick('"tool_use_id":"failed-seat-use"')
    seat_retry_dispatch = pick('"id":"seat-retry-use"')
    late_seat_failure = original.replace(failed_seat_result + "\n", "", 1).replace(
        seat_retry_dispatch, seat_retry_dispatch + "\n" + failed_seat_result, 1)
    audit_failure_result = pick('"tool_use_id":"failed-audit-use"')
    audit_retry_dispatch = pick('"id":"audit-retry-use"')
    late_audit_failure = original.replace(audit_failure_result + "\n", "", 1).replace(
        audit_retry_dispatch, audit_retry_dispatch + "\n" + audit_failure_result, 1)
    seat_dispatch = pick('"id":"seat-use"')
    early_result = original.replace(seat_result + "\n", "", 1).replace(
        seat_dispatch, seat_result + "\n" + seat_dispatch, 1)
    retry_type_line = seat_retry_dispatch.replace('"subagent_type":"Explore"',
                                                   '"subagent_type":"general-purpose"')
    redispatch = pick('"id":"seat-redispatch-use"')
    second_redispatch = redispatch.replace('"id":"seat-redispatch-use"',
                                            '"id":"seat-redispatch2-use"').replace(
                                                "dispatch: 4", "dispatch: 7")
    duplicate_redispatch = original.replace(failed_audit, second_redispatch + "\n" + failed_audit, 1)
    body_target = "round: 2 | kind: cross-exam | dispatch: 2"
    body_retry = "round: 2 | kind: retry | dispatch: 3\\nretry-for: 2"
    crlf_body_drift = original.replace(body_target, body_target + "\\nbody-a\\r\\nbody-b", 1).replace(
        body_retry, body_retry + "\\nbody-a\\nbody-b", 1)
    trailing_body_drift = original.replace(body_target, body_target + "\\nbody", 1).replace(
        body_retry, body_retry + "\\nbody\\n", 1)
    direct_bad_seat = original.replace(
        'seat: — | round: 1 | kind: retry | dispatch: 9\\nretry-for: 8',
        'seat: - | round: 1 | kind: audit | dispatch: 9', 1)
    async_note = pick('<task-notification>')
    async_launch = pick('"id":"seat-retry-use"')
    no_async_terminal = original.replace(async_note + "\n", "", 1)
    mismatched_async_terminal = original.replace("<task-id>retry3</task-id>",
                                                  "<task-id>other-task</task-id>", 1)
    duplicate_async_terminal = original.replace(async_note, async_note + "\n" + async_note, 1)
    early_async_terminal = original.replace(async_note + "\n", "", 1).replace(
        async_launch, async_note + "\n" + async_launch, 1)
    variants = [
        ("malformed-json", "{not-json\n" + original, "malformed-json:1"),
        ("duplicate-tool-id", duplicate, "duplicate-tool-use-id:seat-use"),
        ("duplicate-result-id", duplicate_result, "duplicate-result-id:seat-use"),
        ("duplicate-json-key", original.replace(
            seat_dispatch,
            seat_dispatch.replace('"subagent_type":"Explore"',
                                  '"subagent_type":"Explore","subagent_type":"general-purpose"'), 1),
         "malformed-json:4"),
        ("ambiguous-error", original.replace('"toolUseResult":{"status":"failed_prelaunch","error":"API Error: 503"}',
                                              '"toolUseResult":{}', 1), "ambiguous-result"),
        ("bare-api-error", original.replace('"toolUseResult":{"status":"failed_prelaunch","error":"API Error: 503"}',
                                             '"toolUseResult":"API Error: 503"', 1), "ambiguous-result"),
        ("missing-resolved-model", original.replace(',"resolvedModel":"claude-sonnet"', "", 1),
         "missing-resolved-model"),
        ("async-launch-without-terminal", no_async_terminal, "UNVERIFIABLE\tseat-k3\tno-result"),
        ("async-terminal-wrong-task", mismatched_async_terminal, "terminal-join-mismatch"),
        ("duplicate-async-terminal", duplicate_async_terminal, "ambiguous-terminal-notification"),
        ("async-terminal-before-launch", early_async_terminal, "terminal-before-launch"),
        ("async-terminal-failure", original.replace("<status>completed</status>",
                                                     "<status>failed</status>", 1),
         "FAILED\t3\tretry\tcross-exam\t2"),
        ("missing-retry-link", original.replace("retry-for: 2", "retry-for: x", 1),
         "retry-k3:missing-retry-for"),
        ("forward-retry-link", original.replace("retry-for: 2", "retry-for: 999", 1),
         "retry-k3:retry-target-not-earlier"),
        ("duplicate-retry", duplicate_retry, "retry-k4:duplicate-retry"),
        ("retry-body-drift", original.replace("retry-for: 2", "retry-for: 2\\nleaked position", 1),
         "retry-k3:retry-prompt-drift"),
        ("retry-seat-drift", original.replace(
            "seat: /tmp/expert.md | round: 2 | kind: retry | dispatch: 3",
            "seat: /tmp/other.md | round: 2 | kind: retry | dispatch: 3", 1),
         "retry-k3:retry-prompt-drift"),
        ("retry-round-drift", original.replace(
            "round: 2 | kind: retry | dispatch: 3", "round: 3 | kind: retry | dispatch: 3", 1),
         "retry-k3:retry-prompt-drift"),
        ("retry-type-drift", original.replace(seat_retry_dispatch, retry_type_line, 1),
         "retry-k3:retry-prompt-drift"),
        ("retry-proposition-drift", original.replace(
            "council: choose a database | run: deadbeef | seat: /tmp/expert.md | round: 2 | kind: retry",
            "council: choose a cache | run: deadbeef | seat: /tmp/expert.md | round: 2 | kind: retry", 1),
         "retry-k3:retry-prompt-drift"),
        ("missing-re-dispatch-link", original.replace("re-dispatch-for: 1", "re-dispatch-for: x", 1),
         "re-dispatch-k4:missing-re-dispatch-link"),
        ("forward-re-dispatch-link", original.replace("re-dispatch-for: 1", "re-dispatch-for: 999", 1),
         "re-dispatch-k4:re-dispatch-target-not-earlier"),
        ("duplicate-re-dispatch", duplicate_redispatch, "re-dispatch-k7:duplicate-re-dispatch"),
        ("re-dispatch-body-drift", original.replace(
            "missing-field: strongest-counter", "missing-field: strongest-counter\\nleaked position", 1),
         "re-dispatch-k4:re-dispatch-prompt-drift"),
        ("retry-crlf-body-drift", crlf_body_drift, "retry-k3:retry-prompt-drift"),
        ("retry-trailing-body-drift", trailing_body_drift, "retry-k3:retry-prompt-drift"),
        ("malformed-record-shape", original.replace(
            seat_dispatch, '{"message":{"content":{"type":"tool_use","name":"Agent"}}}', 1),
         "malformed-schema:4"),
        ("result-before-dispatch", early_result, "result-before-dispatch:k1"),
        ("seat-failure-after-retry", late_seat_failure, "retry-k3:retry-target-failure-not-before-retry"),
        ("audit-failure-after-retry", late_audit_failure, "retry-k9:retry-target-failure-not-before-retry"),
        ("direct-audit-noncanonical-seat", direct_bad_seat, "expected one real audit dispatch"),
        ("noncanonical-auditor-seat", original.replace("seat: —", "seat: -"),
         "expected one real audit dispatch"),
    ]
    with tempfile.TemporaryDirectory(prefix="council-auditor-records-") as tmp:
        for label, content, expected in variants:
            root = os.path.join(tmp, label)
            shutil.copytree(fixture_root, root)
            fixture = os.path.join(root, "session.jsonl")
            with open(fixture, "w", encoding="utf-8") as fh:
                fh.write(content)
            run, err = _run_council_auditor_fixture(body, fixture)
            observed = (run.stdout + run.stderr) if run else (err or "")
            if expected not in observed:
                return [f"Claude auditor mutation {label!r} was not rejected as {expected!r}"]
    return []


def _select_consumer(body: str, selector: str):
    if selector == "text":
        return body, None
    if selector.startswith("section:"):
        title = re.escape(selector.removeprefix("section:"))
        found = re.findall(rf"^##\s+{title}\s*$\n(.*?)(?=^##\s+|\Z)", body, re.M | re.S)
        if len(found) != 1:
            return None, f"section selector {selector!r} resolved {len(found)} times, expected exactly one"
        return found[0], None
    if selector.startswith("line:"):
        key = re.escape(selector.removeprefix("line:"))
        found = re.findall(rf"^\s*{key}:\s*(?:\"([^\"]*)\"|'([^']*)'|(.+?))\s*$", body, re.M)
        if len(found) != 1:
            return None, f"line selector {selector!r} resolved {len(found)} times, expected exactly one"
        return next((value for value in found[0] if value != ""), ""), None
    if not selector.startswith("json:"):
        return None, f"unknown selector {selector!r}"
    try:
        value = loads_json_unique(body)
    except (json.JSONDecodeError, ValueError) as err:
        return None, f"JSON selector {selector!r} could not parse its file: {err}"
    for part in selector.removeprefix("json:").split("."):
        match = re.fullmatch(r"([^\[]+)\[name=([^\]]+)\]", part)
        if match:
            value = value.get(match.group(1)) if isinstance(value, dict) else None
            matches = [item for item in value or []
                       if isinstance(item, dict) and item.get("name") == match.group(2)]
            if len(matches) != 1:
                return None, f"JSON selector {selector!r} resolved {len(matches)} list items, expected exactly one"
            value = matches[0]
        else:
            value = value.get(part) if isinstance(value, dict) else None
        if value is None:
            return None, f"JSON selector {selector!r} did not resolve"
    if not isinstance(value, str):
        return None, f"selector {selector!r} did not resolve to text"
    return value, None


def check_consumer_surfaces(contract: dict, files: dict) -> list:
    fails = []
    surfaces = {name: spec for name, spec in contract.get("consumer_surfaces", {}).items()
                if not name.startswith("$")}
    if not surfaces:
        return ["consumer_surfaces declares no checked surface"]
    for name, spec in surfaces.items():
        unknown = set(spec) - {"targets", "required"}
        if unknown:
            fails.append(f"[{name}] unknown consumer-surface field(s) {sorted(unknown)}")
            continue
        if not spec.get("targets") or not spec.get("required"):
            fails.append(f"[{name}] consumer surface has no targets or required literals")
            continue
        if any(not isinstance(target, dict) for target in spec["targets"]):
            fails.append(f"[{name}] consumer surface contains a non-object target")
            continue
        target_keys = [(target.get("file"), target.get("selector")) for target in spec["targets"]]
        if len(target_keys) != len(set(target_keys)):
            fails.append(f"[{name}] consumer surface contains duplicate file/selector targets")
            continue
        for target in spec["targets"]:
            if set(target) != {"file", "selector"}:
                fails.append(f"[{name}] malformed consumer target {target!r}")
                continue
            rel, selector = target["file"], target["selector"]
            body = files.get(rel)
            if body is None:
                fails.append(f"[{name}] consumer surface does not exist: {rel}")
                continue
            selected, err = _select_consumer(body, selector)
            if err:
                fails.append(f"[{name}] {rel}: {err}")
                continue
            for literal in spec.get("required", []):
                if literal not in selected:
                    fails.append(f"[{name}] {rel} {selector}: installation description omits {literal!r}")
            if "ADVISORY" in spec.get("required", []):
                clean = re.sub(r"non-authoriz\w*|does not authorize|cannot authorize|never authorizes?|non-certif\w*",
                               "", selected.lower())
                authority = re.search(
                    r"\b(authoriz\w*|permits?|allow(?:s|ed)?|may proceed|green[- ]light)\b|"
                    r"\b(?:can|should|must)\s+(?:now\s+)?proceed\b|"
                    r"\bproceed(?:s|ed|ing)?\s+with\s+(?:the\s+)?implementation\b|"
                    r"\bimplementation\s+(?:can|should|must)\s+proceed\b|"
                    r"implementation[^.;\n]*(approved|enabled)", clean)
                certified = re.search(r"\badvisory\b.{0,80}\b(certif\w*|audited|audit\s+pass)\b", clean, re.S)
                if authority or certified:
                    fails.append(f"[{name}] {rel} {selector}: ADVISORY description contradicts its non-authorizing, unaudited boundary")
    return fails


def check_families(contract: dict, files: dict) -> list:
    fails = []
    rules = contract.get("families", [])
    if not rules:
        return ["families is empty — token residue checks are disarmed"]
    for rule in rules:
        if not any(re.search(rule["regex"], body) for body in files.values()):
            fails.append(f"family regex {rule['regex']!r} matches nothing anywhere — a dead rule reads exactly like a passing one")
        allowed = set(rule["allowed"])
        for rel, body in sorted(files.items()):
            for found in re.finditer(rule["regex"], body):
                match = found.groupdict().get("token", found.group(0))
                if match not in allowed:
                    fails.append(f"{rel}: {match!r} is not a defined form (allowed: {sorted(allowed)})")
    return fails


def load_markdown() -> dict:
    files = {}
    exts = (".md", ".yaml", ".yml", ".json")   # the entry shells ship too; residue in one ships with it
    for root in ("skills", "council", "opsx", "review-loop", "codex-plugins", "README.md",
                 ".claude-plugin", ".agents"):
        path = os.path.join(ROOT, root)
        if os.path.isfile(path):
            targets = [path]
        else:
            targets = []
            for dirpath, dirnames, filenames in os.walk(path):
                dirnames[:] = [d for d in dirnames if d != ".git"]
                targets += [os.path.join(dirpath, f) for f in filenames if f.endswith(exts)]
        for t in targets:
            with open(t, encoding="utf-8") as fh:
                files[os.path.relpath(t, ROOT)] = fh.read()
    return files


def main() -> int:
    try:
        contract = load_json_unique(CONTRACT)
    except (json.JSONDecodeError, ValueError) as err:
        print(f"check-format: contract JSON is invalid: {err}")
        return 1
    files = load_markdown()
    fails, notes = [], []

    # The contract is the authority every gate below reads. Nothing checked the authority.
    unknown = set(contract) - TOP_LEVEL
    if unknown:
        fails.append(f"unknown top-level contract key(s) {sorted(unknown)} — a typo'd key is a rule nobody runs")
    for k in TOP_LEVEL - {"$comment"}:
        if k not in contract:
            fails.append(f"contract is missing the {k!r} section — declare it, empty if you mean none")
    if not contract.get("families"):
        fails.append("families is empty — every token/marker family is unguarded")
    if not contract["forbidden_everywhere"]["files"]:
        fails.append("forbidden_everywhere.files is empty — the residue scan sees no files")
    # An allowance nothing writes is an allowance nobody audits — and it is how a form the
    # spec forbids gets legalized: widen the list, go green.
    for rule in contract.get("families", []):
        for a in rule["allowed"]:
            if not any(a in b for b in files.values()):
                fails.append(f"family {rule['regex']!r} allows {a!r}, which appears in no file — "
                             f"a dead allowance is how a forbidden form becomes legal")

    # An unlisted spec is a spec nobody checks, and it looks exactly like a spec with
    # nothing to check. Reconcile the contract against what is actually on disk.
    on_disk = {os.path.relpath(p, ROOT) for p in glob.glob(f"{ROOT}/**/SKILL.md", recursive=True)}
    declared = {f for s in contract["skills"].values() for f in s.get("files", [])}
    fails += [f"{o} is checked by nobody — add it to a skill's `files` in the contract"
              for o in sorted(on_disk - declared)]
    fails += [f"the contract lists {g}, which does not exist" for g in sorted(declared - on_disk)]

    # Contract-internal, so it must not ride on whether a catalog happens to be present:
    # this is the check that dies on every path that actually runs otherwise.
    md = contract["catalog"]["min_depth"]
    for rel, body in sorted(files.items()):
        if "-mindepth" in body and f"-mindepth {md}" not in body:
            fails.append(f"{rel}: its `find` uses a depth the contract does not declare "
                         f"(contract min_depth={md})")

    tracked = None
    if os.path.isdir(os.path.join(CATALOG, ".git")):
        out = subprocess.run(["git", "-C", CATALOG, "ls-files", "*.md"],
                             capture_output=True, text=True, check=True).stdout
        tracked = set(out.splitlines())
        min_depth = md
        # Only agent files matter here: an agent carries frontmatter `name:`. A plain
        # CHANGELOG.md upstream must not be able to break this repo's build.
        shallow = []
        for p in tracked:
            if p.count("/") >= min_depth - 1 or re.match(r"(?i)(readme|contributing|security|changelog|code_of_conduct)", p):
                continue
            try:
                with open(os.path.join(CATALOG, p), encoding="utf-8") as fh:
                    if re.search(r"^name:", fh.read(2000), re.M):
                        shallow.append(p)
            except OSError:
                pass
        if shallow:
            fails.append(f"the catalog ships agent files at depth 1 ({shallow[:3]}…) — the specs' "
                         f"-mindepth {contract['catalog']['min_depth']} guard would hide them")
    elif os.environ.get("SKIP_CATALOG_CHECK", "").lower() in ("1", "true", "yes"):
        notes.append("catalog check WAIVED via SKIP_CATALOG_CHECK — the path tables are UNVERIFIED")
    else:
        # Silence here is how a path table becomes fiction: release.sh runs this check, and
        # a green run on a machine with no catalog proves nothing about the paths it ships.
        fails.append(f"no catalog at {CATALOG} — the path tables are unverified. "
                     f"git clone {contract['catalog']['repo']} {CATALOG}  "
                     f"(or SKIP_CATALOG_CHECK=1 to bypass, knowing what that buys)")

    if not contract["forbidden_everywhere"]["patterns"]:
        fails.append("forbidden_everywhere.patterns is empty — the residue scan is disarmed")
    if not contract["forbidden_everywhere"].get("regex_patterns"):
        fails.append("forbidden_everywhere.regex_patterns is missing/empty — the collocation scan is disarmed")
    fails += check_families(contract, files)
    fails += check_twins(files)
    fails += check_claude_copies(files)
    fails += check_council_header_parser(files)
    fails += check_council_auditor_inflight(files)
    fails += check_council_auditor_sidecar_negatives(files)
    fails += check_council_auditor_record_negatives(files)
    fails += check_consumer_surfaces(contract, files)
    fails += check(contract, files, tracked)

    for n in notes:
        print(f"note: {n}")
    if fails:
        print(f"\ncheck-format: {len(fails)} FAILED")
        for f in fails:
            print(f"  ✗ {f}")
        return 1
    print("check-format: OK")
    return 0


def self_test() -> int:
    """A validator with no self-test is the thing it exists to catch.

    Every case below is a defect that actually shipped in this repo, or one shaped
    like it: each must be CAUGHT, and the clean spec must pass.
    """
    base = {
        "forbidden_everywhere": {"patterns": ["jsdelivr"], "files": ["skills"]},
        "catalog": {"repo": "x", "min_depth": 2},
        "skills": {"s": {
            "files": ["skills/s/SKILL.md"], "tiers": ["local"], "marker_prefix": "[embedded",
            "marker_forms": ["[embedded: gone → fix]"],
            "required_verbatim": ["not-run(tier unverified)"],
            "catalog_paths": {"Role": "div/role.md"}, "echo_labels": ["This round:"],
            "tokens": ["CAPPED"], "fenced_must_contain": ["[local: div/role.md]"],
            "exhaustive": [{"regex": r"CAPPED \([^)]*\)", "allowed": ["CAPPED (known)"]}],
        }},
    }
    good = ("This round: local [embedded: gone → fix] not-run(tier unverified) CAPPED (known)\n"
            "```text\n[local: div/role.md]\n```")
    tracked = {"div/role.md"}
    dup = lambda c, f: (lambda d: (f(d), d)[1])(json.loads(json.dumps(c)))

    cases = [
        ("a clean spec passes", base, good, 0),
        ("marker carries a stray backtick", base, good + " `[embedded`: x]", 1),
        ("marker has a leading space", base, good + " [ embedded: x]", 1),
        ("marker is capitalized", base, good + " [Embedded: x]", 1),
        ("an undefined CAPPED variant appears", base, good + " CAPPED (made up)", 1),
        ("[local:] names a path the catalog lacks", base, good + " [local: div/ghost.md]", 1),
        ("a required literal is renamed", base, good.replace("not-run(tier unverified)", "not-run(unverified)"), 1),
        ("an echo label is renamed", base, good.replace("This round:", "Round:"), 1),
        ("a canonical marker form drifts", base, good.replace("→ fix]", "-> fix]"), 1),
        ("removed-behavior residue reappears", base, good + " pulled from jsDelivr", 1),
        ("the copied template lost its tier marker", base, good.replace("```text\n[local: div/role.md]\n```", "```text\nno marker here\n```") + " [local: div/role.md]", 1),
        ("a contract key is typo'd (its rule silently deleted)",
         dup(base, lambda d: d["skills"]["s"].__setitem__("exhastive", d["skills"]["s"].pop("exhaustive"))),
         good + " CAPPED (made up)", 1),
        ("a contract path is fiction",
         dup(base, lambda d: d["skills"]["s"]["catalog_paths"].__setitem__("Ghost", "does/not/exist.md")),
         good, 1),
    ]

    ok = True
    for label, body in (
        ("duplicate top-level contract key", '{"skills":{},"skills":{}}'),
        ("duplicate nested contract key", '{"skills":{"council":{"files":[],"files":[]}}}'),
    ):
        try:
            loads_json_unique(body)
            caught = False
        except ValueError:
            caught = True
        if not caught:
            ok = False
        print(f"  {'✅' if caught else '❌'} {label:<48} caught={caught}  want=True")

    for label, contract, body, expect in cases:
        got = 1 if check(contract, {"skills/s/SKILL.md": body}, tracked) else 0
        if got != expect:
            ok = False
        print(f"  {'✅' if got == expect else '❌'} {label:<48} caught={bool(got)}  want={bool(expect)}")

    # check_twins is a separate code path main() calls; a self-test that only drives
    # check() prints a green tick over code nothing exercised.
    twin_cases = [
        ("twins match", {"skills/s/SKILL.md": "x", "codex-plugins/p/skills/s/SKILL.md": "x"}, 0),
        ("twin content drifted", {"skills/s/SKILL.md": "x", "codex-plugins/p/skills/s/SKILL.md": "y"}, 1),
        ("twin missing entirely", {"skills/s/SKILL.md": "x"}, 1),
    ]
    for label, fs, expect in twin_cases:
        got = 1 if check_twins(fs) else 0
        if got != expect:
            ok = False
        print(f"  {'✅' if got == expect else '❌'} {label:<48} caught={bool(got)}  want={bool(expect)}")

    N, C = "skills/s/SKILL.md", "p/skills/s/SKILL.md"
    copy_cases = [
        ("claude copy differs and dispatches", {N: "neutral", C: "claude subagent_type: x"}, 0),
        ("claude copy flattened onto neutral", {N: "neutral", C: "neutral"}, 1),
        ("claude copy lost its dispatch key", {N: "neutral", C: "claude, no key"}, 1),
        ("neutral spec grew a host key", {N: "neutral subagent_type: x", C: "claude subagent_type: x"}, 1),
        ("claude copy missing entirely", {N: "neutral"}, 1),
        ("codex twin is not a claude copy", {N: "neutral", "codex-plugins/p/skills/s/SKILL.md": "neutral"}, 1),
    ]
    for label, fs, expect in copy_cases:
        got = 1 if check_claude_copies(fs) else 0
        if got != expect:
            ok = False
        print(f"  {'✅' if got == expect else '❌'} {label:<48} caught={bool(got)}  want={bool(expect)}")

    kinds = "|".join(COUNCIL_DISPATCH_KINDS)
    header = ("HEADER_RE=re.compile(r'^council: (?P<proposition>.+?) \\| run: (?P<run>[0-9a-f]{8}) "
              "\\| seat: (?P<seat>.+?) \\| round: (?P<round>\\d+) \\| kind: "
              f"(?P<kind>{kinds}) \\| dispatch: (?P<k>\\d+)$')")
    header_cases = [
        ("council header parser matches its template", header, 0),
        ("council header parser omits kind field", header.replace(f" \\| kind: (?P<kind>{kinds})", ""), 1),
        ("council header parser omits one kind", header.replace("|label|audit", "|audit"), 1),
        ("council header parser is missing", "no parser", 1),
    ]
    for label, body, expect in header_cases:
        got = 1 if check_council_header_parser({"council/skills/council/references/auditor-enumerator.md": body}) else 0
        if got != expect:
            ok = False
        print(f"  {'✅' if got == expect else '❌'} {label:<48} caught={bool(got)}  want={bool(expect)}")

    got = 1 if check_council_header_parser({}) else 0
    if got != 1:
        ok = False
    print(f"  {'✅' if got == 1 else '❌'} {'council auditor reference is absent':<48} caught={bool(got)}  want=True")

    actual = load_markdown()
    inflight_cases = [
        ("auditor handles tool/failure/retry/in-flight", actual[COUNCIL_AUDITOR_REF], 0),
        ("in-flight audit retry verifies itself",
         actual[COUNCIL_AUDITOR_REF].replace('    if current and stt=="PENDING": ',
                                             '    if False and current and stt=="PENDING": '), 1),
        ("disabled sidecar scan is caught",
         actual[COUNCIL_AUDITOR_REF].replace('    tools(hits[0],f"seat-k{kk}")\n',
                                             '    pass # sidecar scan disabled\n'), 1),
        ("failed-dispatch handling is exercised",
         actual[COUNCIL_AUDITOR_REF].replace('    if stt=="FAILED-PRELAUNCH": ',
                                             '    if False and stt=="FAILED-PRELAUNCH": '), 1),
    ]
    for label, body, expect in inflight_cases:
        got = 1 if check_council_auditor_inflight({COUNCIL_AUDITOR_REF: body}) else 0
        if got != expect:
            ok = False
        print(f"  {'✅' if got == expect else '❌'} {label:<48} caught={bool(got)}  want={bool(expect)}")

    got = 1 if check_council_auditor_sidecar_negatives(actual) else 0
    if got != 0:
        ok = False
    print(f"  {'✅' if got == 0 else '❌'} {'missing/duplicate sidecars are rejected':<48} caught={not bool(got)}  want=True")

    got = 1 if check_council_auditor_record_negatives(actual) else 0
    if got != 0:
        ok = False
    print(f"  {'✅' if got == 0 else '❌'} {'malformed records/retry links are rejected':<48} caught={not bool(got)}  want=True")

    no_body_equality = dict(actual)
    no_body_equality[COUNCIL_AUDITOR_REF] = actual[COUNCIL_AUDITOR_REF].replace(
        ' or d["body"]!=target["raw"]', '', 1)
    got = 1 if check_council_auditor_record_negatives(no_body_equality) else 0
    if got != 1:
        ok = False
    print(f"  {'✅' if got == 1 else '❌'} {'deleted retry body equality is caught':<48} caught={bool(got)}  want=True")

    no_redispatch_equality = dict(actual)
    no_redispatch_equality[COUNCIL_AUDITOR_REF] = actual[COUNCIL_AUDITOR_REF].replace(
        ' or d["body"]!=target["body"]', '', 1)
    got = 1 if check_council_auditor_record_negatives(no_redispatch_equality) else 0
    if got != 1:
        ok = False
    print(f"  {'✅' if got == 1 else '❌'} {'deleted re-dispatch body equality is caught':<48} caught={bool(got)}  want=True")

    surface_contract = {"consumer_surfaces": {"council": {
        "targets": [
            {"file": "manifest.json", "selector": "json:description"},
            {"file": "manifest.json", "selector": "json:longDescription"},
        ], "required": ["ADVISORY", "CONVERGED", "non-authorizing"]}}}
    surface_cases = [
        ("consumer fields name both assurance tiers",
         '{"description":"ADVISORY CONVERGED non-authorizing","longDescription":"ADVISORY CONVERGED non-authorizing"}', 0),
        ("one consumer field hides advisory",
         '{"description":"CONVERGED only","longDescription":"ADVISORY CONVERGED non-authorizing"}', 1),
        ("duplicate JSON key is rejected",
         '{"description":"ADVISORY CONVERGED non-authorizing","description":"ADVISORY CONVERGED non-authorizing","longDescription":"ADVISORY CONVERGED non-authorizing"}', 1),
        ("consumer description is missing", None, 1),
    ]
    for label, body, expect in surface_cases:
        fs = {} if body is None else {"manifest.json": body}
        got = 1 if check_consumer_surfaces(surface_contract, fs) else 0
        if got != expect:
            ok = False
        print(f"  {'✅' if got == expect else '❌'} {label:<48} caught={bool(got)}  want={bool(expect)}")

    got = 1 if check_consumer_surfaces({"consumer_surfaces": {}}, {}) else 0
    if got != 1:
        ok = False
    print(f"  {'✅' if got == 1 else '❌'} {'consumer surface contract is empty':<48} caught={bool(got)}  want=True")

    duplicate_target = json.loads(json.dumps(surface_contract))
    duplicate_target["consumer_surfaces"]["council"]["targets"].append(
        {"file": "manifest.json", "selector": "json:description"})
    got = 1 if check_consumer_surfaces(duplicate_target, {
        "manifest.json": '{"description":"ADVISORY CONVERGED non-authorizing",'
                         '"longDescription":"ADVISORY CONVERGED non-authorizing"}'}) else 0
    if got != 1:
        ok = False
    print(f"  {'✅' if got == 1 else '❌'} {'duplicate consumer target is rejected':<48} caught={bool(got)}  want=True")

    malformed_target = json.loads(json.dumps(surface_contract))
    malformed_target["consumer_surfaces"]["council"]["targets"] = ["manifest.json"]
    got = 1 if check_consumer_surfaces(malformed_target, {"manifest.json": "{}"}) else 0
    if got != 1:
        ok = False
    print(f"  {'✅' if got == 1 else '❌'} {'non-object consumer target is rejected':<48} caught={bool(got)}  want=True")

    list_contract = {"consumer_surfaces": {"council": {
        "targets": [{"file": "manifest.json", "selector": "json:plugins[name=council].description"}],
        "required": ["ADVISORY"]}}}
    duplicate_list = '{"plugins":[{"name":"council","description":"ADVISORY"},{"name":"council","description":"ADVISORY"}]}'
    got = 1 if check_consumer_surfaces(list_contract, {"manifest.json": duplicate_list}) else 0
    if got != 1:
        ok = False
    print(f"  {'✅' if got == 1 else '❌'} {'duplicate selected list item is rejected':<48} caught={bool(got)}  want=True")

    line_contract = {"consumer_surfaces": {"council": {
        "targets": [{"file": "SKILL.md", "selector": "line:description"}],
        "required": ["ADVISORY", "CONVERGED", "non-authorizing"]}}}
    for label, body, expect in (
        ("frontmatter description is selected exactly",
         "---\nname: council\ndescription: CONVERGED or non-authorizing ADVISORY\n---\n", 0),
        ("duplicate frontmatter description is rejected",
         "---\ndescription: CONVERGED or non-authorizing ADVISORY\ndescription: CONVERGED only\n---\n", 1),
        ("authorizing advisory contradiction is rejected",
         "description: ADVISORY is non-authorizing but authorizes implementation; CONVERGED\n", 1),
        ("implementation-can-proceed contradiction is rejected",
         "description: ADVISORY is non-authorizing, but implementation can proceed; CONVERGED\n", 1),
        ("green-light contradiction is rejected",
         "description: ADVISORY is non-authorizing but is a green light to implement; CONVERGED\n", 1),
        ("proceed-with-implementation contradiction is rejected",
         "description: ADVISORY is non-authorizing; proceed with implementation; CONVERGED\n", 1),
    ):
        got = 1 if check_consumer_surfaces(line_contract, {"SKILL.md": body}) else 0
        if got != expect:
            ok = False
        print(f"  {'✅' if got == expect else '❌'} {label:<48} caught={bool(got)}  want={bool(expect)}")

    section_contract = {"consumer_surfaces": {"council": {
        "targets": [{"file": "README.md", "selector": "section:Council"}],
        "required": ["ADVISORY", "CONVERGED", "non-authorizing"]}}}
    displaced = "ADVISORY CONVERGED non-authorizing\n## Council\nCouncil text without assurance terms\n## Next\n"
    got = 1 if check_consumer_surfaces(section_contract, {"README.md": displaced}) else 0
    if got != 1:
        ok = False
    print(f"  {'✅' if got == 1 else '❌'} {'README literals outside council section fail':<48} caught={bool(got)}  want=True")

    parsed_contract = load_json_unique(CONTRACT)
    advisory = next(rule for rule in parsed_contract["families"] if "ADVISORY" in rule["regex"])
    family_contract = {"families": [advisory]}
    family_cases = [
        ("canonical ADVISORY family passes", "ADVISORY (debate-converged; unaudited)", 0),
        ("certified ADVISORY variants are rejected",
         "ADVISORY (debate-converged; unaudited)\nADVISORY-CERTIFIED (audit PASS)\n"
         "ADVISORY CERTIFIED (audit PASS)\nADVISORY FULLY CERTIFIED (audit PASS)\n"
         "ADVISORY-CERTIFIED-AUDITED (audit PASS)\nADVISORY_CERTIFIED (audit PASS)\n"
         "ADVISORY/CERTIFIED (audit PASS)\nADVISORY[CERTIFIED] (audit PASS)\n"
         "ADVISORY--CERTIFIED (audit PASS)", 1),
    ]
    for label, body, expect in family_cases:
        got = 1 if check_families(family_contract, {"fixture": body}) else 0
        if got != expect:
            ok = False
        print(f"  {'✅' if got == expect else '❌'} {label:<48} caught={bool(got)}  want={bool(expect)}")

    # 家族正则是行首/表格锚定的，行中散文里的越权 token 靠 forbidden_everywhere 兜底 —— 这里证明兜底真的兜。
    # 探针刻意选 trio 专属的形态（字面量表抓不到），否则删掉整个 regex_patterns 探针照样绿。
    forb_contract = {"forbidden_everywhere": parsed_contract["forbidden_everywhere"], "skills": {}}
    forb_cases = [
        ("mid-line trio-exclusive ADVISORY (audited) caught", "…the run may emit ADVISORY (audited) instead.", 1),
        ("all-caps reversed CERTIFIED ADVISORY caught", "…ships a CERTIFIED ADVISORY result to consumers.", 1),
        ("canonical-token trailing escalation caught", "…ADVISORY (debate-converged; unaudited) audit PASS…", 1),
        ("canonical tokens alone do not trip the trio",
         "emit **`ADVISORY (debate-converged; unaudited)`** or **`ADVISORY (N open; unaudited)`**, a non-certifying result", 0),
    ]
    for label, body, expect in forb_cases:
        got = 1 if check(forb_contract, {"skills/council/SKILL.md": body}, None) else 0
        if got != expect:
            ok = False
        print(f"  {'✅' if got == expect else '❌'} {label:<48} caught={bool(got)}  want={bool(expect)}")

    council_spec = parsed_contract["skills"]["council"]
    council_contract = {
        "forbidden_everywhere": {"patterns": [], "files": []},
        "skills": {"council": council_spec},
    }
    council_files = {rel: actual[rel] for rel in council_spec["files"]}
    tracked_council = set(council_spec["catalog_paths"].values())
    for label, replacement in (
        ("bare council ADVISORY table token", "**`ADVISORY`**"),
        ("bracketed council ADVISORY table token", "**`ADVISORY [N open; unaudited]`**"),
    ):
        mutated = dict(council_files)
        rel = "skills/council/SKILL.md"
        mutated[rel] = mutated[rel].replace("**`ADVISORY (N open; unaudited)`**", replacement, 1)
        got = 1 if check(council_contract, mutated, tracked_council) else 0
        if got != 1:
            ok = False
        print(f"  {'✅' if got == 1 else '❌'} {label:<48} caught={bool(got)}  want=True")
    for label, literal in (
        ("council attestation gate is pinned", "post-confirmation-attestation"),
        ("council confirmation evidence is pinned", "platform-authored confirmation record"),
        ("council re-dispatch linkage is pinned", "re-dispatch-for: <superseded k>"),
        ("council evidence envelope is pinned", "post-candidate evidence envelope"),
        ("council pre-seat audit pins are pinned", "predate the first seat dispatch"),
    ):
        mutated = dict(council_files)
        rel = "skills/council/SKILL.md"
        mutated[rel] = mutated[rel].replace(literal, "removed-contract-literal")
        got = 1 if check(council_contract, mutated, tracked_council) else 0
        if got != 1:
            ok = False
        print(f"  {'✅' if got == 1 else '❌'} {label:<48} caught={bool(got)}  want=True")
    displaced = dict(council_files)
    rel = "skills/council/SKILL.md"
    displaced[rel] = displaced[rel].replace("post-confirmation-attestation", "removed-contract-literal")
    displaced[rel] += "\n<!-- post-confirmation-attestation -->\n"
    got = 1 if check(council_contract, displaced, tracked_council) else 0
    if got != 1:
        ok = False
    print(f"  {'✅' if got == 1 else '❌'} {'out-of-section displaced attestation literal caught':<48} caught={bool(got)}  want=True")
    print("\nself-test: OK" if ok else "\nself-test: FAILED — the checker cannot catch what it claims to")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(self_test() if "--self-test" in sys.argv else main())
