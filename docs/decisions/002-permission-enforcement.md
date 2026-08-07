# ADR 002: Server-side permission enforcement

- Status: accepted
- Context: interface controls can remain stale after a role or permission
  change.

## Decision

Use the interface to guide the user experience, but validate all date,
dependency, color, and ordering operations on the backend.

## Consequences

- An outdated or manipulated client cannot bypass authorization.
- Each sensitive field must be associated with its corresponding permission.
- Integration tests must verify `403` responses in addition to interface
  behavior.
