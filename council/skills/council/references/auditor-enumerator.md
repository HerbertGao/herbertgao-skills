# Claude Auditor Enumerator

Run this script before A0-A9 or a post-confirmation attestation. Supply the payload run nonce and current auditor dispatch `k` as its two arguments. It finds one main JSONL by parsing real `Agent` tool-use records, then prints its absolute `LOG` path, every successful `DISPATCH` with one canonical sidecar locator, every failed original as `FAILED`, plus moderator and seat write-capable tool calls. `UNVERIFIABLE` or a nonzero exit is an audit failure.

```bash
python3 - '<run nonce>' '<auditor dispatch k>' <<'EOF'
import json,sys,re,hashlib,os,glob,xml.etree.ElementTree as ET
NONCE,AUDIT_K=sys.argv[1:3]
HEADER_RE=re.compile(r'^council: (?P<proposition>.+?) \| run: (?P<run>[0-9a-f]{8}) \| seat: (?P<seat>.+?) \| round: (?P<round>\d+) \| kind: (?P<kind>seat|re-dispatch|retry|cross-exam|DA|DA-final|tie-breaker|label|audit) \| dispatch: (?P<k>\d+)$')
def blocks(r):
    if not isinstance(r,dict) or not isinstance(r.get("message"),dict): return []
    c=r["message"].get("content")
    return c if isinstance(c,list) else []
def unique_object(pairs):
    out={}
    for k,v in pairs:
        if k in out: raise ValueError(f"duplicate-key:{k}")
        out[k]=v
    return out
def decode(line): return json.loads(line,object_pairs_hook=unique_object)
logs=[]
for path in glob.glob(os.path.expanduser("~/.claude/projects/*/*.jsonl")):
    for line in open(path):
        try: r=decode(line)
        except: continue                 # discovery spans unrelated historical logs
        for b in blocks(r):
            if isinstance(b,dict) and b.get("type")=="tool_use" and b.get("name")=="Agent":
                p=((b.get("input") or {}).get("prompt") or ""); m=HEADER_RE.fullmatch(p.partition("\n")[0])
                current=m and m["run"]==NONCE and m["k"]==AUDIT_K
                if current and m["seat"]=="—" and m["kind"] in ("audit","retry"):
                    logs.append(os.path.abspath(path))
if len(set(logs)) != 1: raise SystemExit("FAIL: replay — expected one real audit dispatch")
LOG=logs[0]
def load(path):
    out=[]
    for n,line in enumerate(open(path),1):
        try: r=decode(line)
        except Exception: raise SystemExit(f"UNVERIFIABLE\t{path}\tmalformed-json:{n}")
        msg=r.get("message") if isinstance(r,dict) else None
        content=msg.get("content") if isinstance(msg,dict) else None
        if not isinstance(r,dict) or ("message" in r and (not isinstance(msg,dict) or not isinstance(content,(list,str)))) or (isinstance(content,list) and any((not isinstance(b,dict) for b in content))):
            raise SystemExit(f"UNVERIFIABLE\t{path}\tmalformed-schema:{n}")
        out.append((n,r))
    return out
def task_notification(r,n):
    msg=r.get("message") if isinstance(r,dict) else None; c=msg.get("content") if isinstance(msg,dict) else None
    if not isinstance(c,str) or not c.startswith("<task-notification>"): return None
    try: root=ET.fromstring(c)
    except Exception: raise SystemExit(f"UNVERIFIABLE\tlog\tmalformed-task-notification:{n}")
    if root.tag!="task-notification": raise SystemExit(f"UNVERIFIABLE\tlog\tmalformed-task-notification:{n}")
    values={}
    for child in root:
        if child.tag not in ("task-id","tool-use-id","status"): continue
        if child.tag in values or list(child): raise SystemExit(f"UNVERIFIABLE\tlog\tmalformed-task-notification:{n}")
        values[child.tag]=(child.text or "").strip()
    if set(values)!={"task-id","tool-use-id","status"} or not values["task-id"] or not values["tool-use-id"] or values["status"] not in ("completed","failed"):
        raise SystemExit(f"UNVERIFIABLE\tlog\tmalformed-task-notification:{n}")
    return {"n":n,"aid":values["task-id"],"tid":values["tool-use-id"],"status":values["status"]}
records=load(LOG); nonce_calls={}; births=[]; result_rows={}; dispatches=[]; tool_ids=set(); terminal_rows={}
for n,r in records:
    note=task_notification(r,n)
    if note: terminal_rows.setdefault(note["tid"],[]).append(note)
    t=r.get("toolUseResult")
    for b in blocks(r):
        if not isinstance(b,dict): continue
        if b.get("type")=="tool_use":
            tid=b.get("id")
            if tid in tool_ids: raise SystemExit(f"UNVERIFIABLE\tlog\tduplicate-tool-use-id:{tid}")
            tool_ids.add(tid)
            if b.get("name")=="Bash" and ((b.get("input") or {}).get("command") or "").strip()=="openssl rand -hex 4": nonce_calls[tid]=n
            if b.get("name")=="Agent":
                i=b.get("input") or {}; p=i.get("prompt") or ""; hdr,_,raw=p.partition("\n"); m=HEADER_RE.fullmatch(hdr)
                rfor=rdfor=missing=None; body=raw
                if m and m["kind"]=="retry":
                    link,_,body=raw.partition("\n"); rfor=re.fullmatch(r'retry-for: (\d+)',link)
                elif m and m["kind"]=="re-dispatch":
                    link,_,tail=raw.partition("\n"); field,_,body=tail.partition("\n")
                    rdfor=re.fullmatch(r're-dispatch-for: (\d+)',link); missing=re.fullmatch(r'missing-field: ([a-z0-9-]+)',field) if rdfor else None
                dispatches.append({"n":n,"tid":tid,"p":p,"hdr":hdr,"raw":raw,"m":m,"rfor":rfor.group(1) if rfor else None,"rdfor":rdfor.group(1) if rdfor else None,"missing":missing.group(1) if missing else None,"body":body,"st":i.get("subagent_type")})
        elif b.get("type")=="tool_result":
            tid=b.get("tool_use_id")
            if tid in result_rows: raise SystemExit(f"UNVERIFIABLE\tlog\tduplicate-result-id:{tid}")
            result_rows[tid]=(n,t,b)
            if tid in nonce_calls and NONCE in json.dumps([t,b],ensure_ascii=False): births.append(nonce_calls[tid])
if len(births)!=1: raise SystemExit("FAIL: replay — expected one nonce birth event")
BIRTH=births[0]; by_k={}; retry_count={}; redispatch_count={}; problems=[]
def state(d):
    row=result_rows.get(d["tid"])
    if not row: return ("PENDING",None,None,None,None)
    rn,t,b=row
    prelaunch=isinstance(t,dict) and t.get("status")=="failed_prelaunch"
    if b.get("is_error") and prelaunch and not t.get("agentId"): return ("FAILED-PRELAUNCH",None,None,rn,None)
    if not isinstance(t,dict): return ("UNVERIFIABLE",None,None,rn,"ambiguous-result")
    aid=t.get("agentId"); mdl=t.get("resolvedModel")
    if not isinstance(aid,str) or not aid.strip(): return ("UNVERIFIABLE",None,None,rn,"ambiguous-result")
    if not isinstance(mdl,str) or not mdl.strip(): return ("UNVERIFIABLE",aid,None,rn,"missing-resolved-model")
    status=t.get("status"); launched=t.get("isAsync") is True or status=="async_launched"
    notes=terminal_rows.get(d["tid"],[])
    if launched:
        exact=[note for note in notes if note["aid"]==aid]
        if len(exact)>1: return ("UNVERIFIABLE",aid,mdl,rn,"ambiguous-terminal-notification")
        if not exact:
            why="terminal-join-mismatch" if notes else None
            return (("UNVERIFIABLE" if why else "PENDING"),aid,mdl,rn,why)
        note=exact[0]
        if note["n"]<=rn: return ("UNVERIFIABLE",aid,mdl,rn,"terminal-before-launch")
        return (("SUCCESS" if note["status"]=="completed" else "FAILED-STARTED"),aid,mdl,note["n"],None)
    if notes: return ("UNVERIFIABLE",aid,mdl,rn,"unexpected-terminal-notification")
    if status=="failed": return ("FAILED-STARTED",aid,mdl,rn,None)
    if status not in (None,"completed","success") or b.get("is_error"):
        return ("UNVERIFIABLE",aid,mdl,rn,"ambiguous-result")
    return ("SUCCESS",aid,mdl,rn,None)
for d in dispatches:
    m=d["m"]
    if not m or d["n"]<BIRTH: continue
    if m["k"] in by_k: problems.append(f"duplicate-k:{m['k']}")
    by_k[m["k"]]=d
    if state(d)[3] is not None and state(d)[3]<=d["n"]: problems.append(f"result-before-dispatch:k{m['k']}")
for d in dispatches:
    m=d["m"]
    if not m or d["n"]<BIRTH or m["kind"]!="retry": continue
    target=by_k.get(d["rfor"] or "")
    reason=None
    if not d["rfor"]: reason="missing-retry-for"
    elif not target or target["n"]>=d["n"]: reason="retry-target-not-earlier"
    elif state(target)[0] not in ("FAILED-PRELAUNCH","FAILED-STARTED"): reason="retry-target-not-failed"
    elif state(target)[3]>=d["n"]: reason="retry-target-failure-not-before-retry"
    elif target["m"]["kind"]=="retry": reason="second-retry"
    elif any((m[x]!=target["m"][x] for x in ("proposition","run","seat","round"))) or d["st"]!=target["st"] or d["body"]!=target["raw"]: reason="retry-prompt-drift"
    retry_count[d["rfor"]]=retry_count.get(d["rfor"],0)+1
    if retry_count[d["rfor"]]>1: reason="duplicate-retry"
    if reason: problems.append(f"retry-k{m['k']}:{reason}")
for d in dispatches:
    m=d["m"]
    if not m or d["n"]<BIRTH or m["kind"]!="re-dispatch": continue
    target=by_k.get(d["rdfor"] or ""); reason=None
    if not d["rdfor"] or not d["missing"]: reason="missing-re-dispatch-link"
    elif not target or target["n"]>=d["n"]: reason="re-dispatch-target-not-earlier"
    elif state(target)[0]!="SUCCESS": reason="re-dispatch-target-not-successful"
    elif target["m"]["kind"]=="re-dispatch": reason="second-re-dispatch"
    elif any((m[x]!=target["m"][x] for x in ("proposition","run","seat","round"))) or d["st"]!=target["st"] or d["body"]!=target["body"]: reason="re-dispatch-prompt-drift"
    redispatch_count[d["rdfor"]]=redispatch_count.get(d["rdfor"],0)+1
    if redispatch_count[d["rdfor"]]>1: reason="duplicate-re-dispatch"
    if reason: problems.append(f"re-dispatch-k{m['k']}:{reason}")
for p in problems: print("UNVERIFIABLE\tlog\t"+p)
def tools(path,who):
    for n,r in load(path):
        for b in blocks(r):
            if b.get("type")!="tool_use": continue
            if b.get("name")=="Agent" and who!="moderator": print(f"UNVERIFIABLE\t{who}\tdescendant-dispatch:{b.get('id')}")
            elif b.get("name")!="Agent": print("TOOL\t"+who+f"\trecord:{n}\t"+str(b.get("name"))+"\t"+json.dumps(b.get("input") or {}))
print("LOG\t"+LOG); tools(LOG,"moderator")
for d in dispatches:
    m=d["m"]
    if d["n"]<BIRTH:
        print("\t".join(["PRE-RUN",str(d["n"]),d["tid"],hashlib.sha256(d["p"].encode()).hexdigest(),d["hdr"]])); continue
    kk=m["k"] if m else "NO-HEADER"; kind=m["kind"] if m else "NO-KIND"; seat=m["seat"] if m else "NO-SEAT"
    link=d["rfor"] if kind=="retry" else (d["rdfor"] if kind=="re-dispatch" else None); target=by_k.get(link or "")
    origin=d; seen=set()
    while origin.get("m") and origin["m"]["kind"] in ("retry","re-dispatch") and origin["m"]["k"] not in seen:
        seen.add(origin["m"]["k"]); olink=origin["rfor"] if origin["m"]["kind"]=="retry" else origin["rdfor"]; nxt=by_k.get(olink or "")
        if not nxt: break
        origin=nxt
    functional=origin["m"]["kind"] if origin.get("m") else kind
    stt,aid,mdl,_,why=state(d); current=kk==AUDIT_K and seat=="—" and kind in ("audit","retry")
    prefix=[kk,kind,functional,str(link),d["tid"],str(aid),str(d["st"]),str(mdl),hashlib.sha256(d["p"].encode()).hexdigest()]
    if current and stt=="PENDING": print("\t".join(["DISPATCH"]+prefix+["IN-FLIGHT",d["hdr"]])); continue
    hits=sorted(os.path.abspath(p) for p in glob.glob(f"{os.path.dirname(LOG)}/*/subagents/agent-{aid}.jsonl")) if aid else []
    locator=hits[0] if len(hits)==1 else ("NONE" if not hits else f"AMBIGUOUS:{len(hits)}")
    if stt=="FAILED-PRELAUNCH": print("\t".join(["FAILED"]+prefix+["PRELAUNCH",d["hdr"]])); continue
    tag="FAILED" if stt=="FAILED-STARTED" else "DISPATCH"; print("\t".join([tag]+prefix+[locator,d["hdr"]]))
    if stt=="UNVERIFIABLE": print(f"UNVERIFIABLE\tseat-k{kk}\t{why or 'ambiguous-result'}"); continue
    if stt=="PENDING": print(f"UNVERIFIABLE\tseat-k{kk}\tno-result"); continue
    if len(hits)!=1:
        why="no-sidecar" if not hits else f"duplicate-sidecars:{len(hits)}"; print(f"UNVERIFIABLE\tseat-k{kk}\t{why}\t{aid}"); continue
    tools(hits[0],f"seat-k{kk}")
EOF
```
