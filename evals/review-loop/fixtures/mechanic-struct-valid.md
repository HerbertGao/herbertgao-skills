TERMINAL: continue
ANCHORS: traced the retry+breaker composition on a fully-down backend
FINDINGS: blocker: the guarantee "retried its full 3 times before the breaker trips" is false. The initial attempt is failure #1, so failures run 1,2,3 across attempts 1,2,3 while retries run on attempts 2,3,4. The breaker trips at attempt 3 (the 2nd retry); the 3rd retry (attempt 4) never fires — a transient blip gets only 2 retries, not 3. Task 4's test pins the breaker in isolation and misses the interaction.
SUFFIXES: none

An internal contradiction between the two constants and the stated guarantee, kept in scope by
the not-yet-implemented rule. Unresolved blocker ⇒ the round rejects, no terminal token.
