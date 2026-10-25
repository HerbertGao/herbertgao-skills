# Expected-output worksheet

Complete one worksheet before executing each selected journey. Replace every angle-bracket placeholder; delete optional rows only when they are genuinely irrelevant.

```text
Journey: <name>
Actor: <single role, tenant, and permissions>
Goal: <user task in one sentence>
Start state: <known fixtures and application state>

Postconditions
PC-1 Final state
  Expected: <exact entity, status, or workflow state>
  Read-back: <UI location, public API, or authorized read-only query>
  Evidence: <assigned after execution>
  Result: <PASS | FAIL | BLOCKED>

PC-2 Required values
  Expected: <exact important fields, amounts, ownership, or relationships>
  Read-back: <independent observation method>
  Evidence: <E#>
  Result: <PASS | FAIL | BLOCKED>

PC-3 Required side effects
  Expected: <exact notifications, child records, exports, counts, or jobs>
  Read-back: <independent observation method>
  Evidence: <E#>
  Result: <PASS | FAIL | BLOCKED>

PC-4 Forbidden side effects
  Expected: <duplicates, cross-tenant writes, extra charges, or other effects that must not occur>
  Read-back: <independent observation method>
  Evidence: <E#>
  Result: <PASS | FAIL | BLOCKED>

Asynchronous completion
  Accepted state: <immediate externally visible state, or not applicable>
  Final state: <observable completion condition>
  Product completion deadline: <contractual maximum, or none>
  Bounded wait: <maximum interval and poll method>

Evidence plan
  Start-state evidence: <screenshot, query, or fixture ID>
  Write read-back: <independent business read>
  Refresh / relogin check: <required or not applicable>
  Cleanup: <authorized test-data cleanup, or none>
```

## Worked generic example

Use this shape, not these invented product values, for a concrete review:

```text
PC-1 Final state
  Expected: Order ORD-1042 is visible to customer A with status `paid`.
  Read-back: Reopen the order-details page in a fresh session.
  Evidence: E7
  Result: PASS

PC-2 Required values
  Expected: Total is USD 24.00, currency is USD, and owner is customer A.
  Read-back: Query the public order-details endpoint as customer A.
  Evidence: E8
  Result: PASS

PC-3 Required side effects
  Expected: Exactly one receipt exists for ORD-1042.
  Read-back: Open the customer's receipt list and inspect the receipt.
  Evidence: E9
  Result: PASS

PC-4 Forbidden side effects
  Expected: No second order or receipt exists for the same submission.
  Read-back: Repeat the order-list and receipt-list queries after the retry.
  Evidence: E10
  Result: PASS
```

A missing read-back method is an unresolved worksheet, not permission to mark the condition passed.
