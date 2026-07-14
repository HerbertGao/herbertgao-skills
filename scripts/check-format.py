#!/usr/bin/env python3
"""Check every SKILL.md against contracts/format.json.

The specs must stay self-contained (npx skills add ships only SKILL.md), so the
canonical strings are spelled inside them. This makes that spelling checkable
instead of hoping a prose reviewer notices a stray character in a literal that
some evaluator is supposed to match.

Run: scripts/check-format.py            exit 1 on any failure
     scripts/check-format.py --self-test   prove the checks can actually fail
"""
import glob
import json
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CONTRACT = os.path.join(ROOT, "contracts", "format.json")
CATALOG = os.path.expanduser(os.environ.get("AGENCY_AGENTS", "~/.agency-agents"))

# Every field is declared, always: an absent key and a misspelled one look identical,
# so "no rule here" has to be said out loud as [] rather than by silence.
FIELDS = {"files", "tiers", "marker_prefix", "marker_forms", "required_verbatim",
          "catalog_paths", "echo_labels", "tokens", "exhaustive", "fenced_must_contain"}

# Same discipline at the top level: a typo'd key must not silently delete its own rule.
TOP_LEVEL = {"$comment", "forbidden_everywhere", "skills", "catalog", "families"}

# Deliberately looser than the literal it checks against: the malformed spellings are
# the whole point, so the regex has to SEE them before the assertion can reject them.
# Bounded to one line — a marker never spans one, and an unbounded run swallows the
# evaluator's own bracket-less prefix literal and everything after it.
MARKER_RE = re.compile(r"[\[［]\s*[Ee][Mm][Bb][Ee]?[Dd]+[Ee]?[Dd]?[^\]］\n]*[\]］]")  # embeded / ［embedded］ / Embedded…
LOCAL_PATH_RE = re.compile(r"\[local: ([A-Za-z0-9._/-]+\.md)\]")
# The ladder's own backtick paths — the table the agent actually reads to resolve a lane.
SPEC_PATH_RE = re.compile(r"`([a-z0-9-]+/[a-z0-9./-]+\.md)`")


def check(contract: dict, files: dict, tracked) -> list:
    """contract + file bodies + the catalog's tracked paths -> failures.

    Pure, so --self-test can drive it with synthetic specs. `tracked` is None when no
    catalog is available; main() decides whether that absence is fatal.
    """
    fails = []

    def fail(msg):
        fails.append(msg)

    for root in contract["forbidden_everywhere"]["files"]:
        for rel, body in files.items():
            if not (rel == root or rel.startswith(root + "/")):
                continue
            for p in contract["forbidden_everywhere"]["patterns"]:
                if p.lower() in body.lower():
                    fail(f"forbidden string {p!r} in {rel} — a removed behavior leaves no notice behind")

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
            for lit in spec["required_verbatim"]:
                if lit not in body:
                    fail(f"[{name}] {rel}: required string missing verbatim: {lit!r}")
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
    with open(CONTRACT, encoding="utf-8") as fh:
        contract = json.load(fh)
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
    for rule in contract["families"]:
        if not any(re.search(rule["regex"], b) for b in files.values()):
            fails.append(f"family regex {rule['regex']!r} matches nothing anywhere — "
                         f"a dead rule reads exactly like a passing one")
    # F1: families are repo-wide by declaration; run them where they said they run.
    for rel, body in sorted(files.items()):
        for rule in contract["families"]:
            allowed = set(rule["allowed"])
            for m in re.findall(rule["regex"], body):
                if m not in allowed:
                    fails.append(f"{rel}: {m!r} is not a defined form (allowed: {sorted(allowed)})")
    fails += check_twins(files)
    fails += check_claude_copies(files)
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
    print("\nself-test: OK" if ok else "\nself-test: FAILED — the checker cannot catch what it claims to")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(self_test() if "--self-test" in sys.argv else main())
