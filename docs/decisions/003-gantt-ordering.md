# ADR 003: Ordering as a business rule

- Status: accepted
- Context: different entity types and bulk operations may compete for the same
  Gantt position.

## Decision

Calculate and synchronize positions in the backend domain service. A unique
database constraint protects integrity, while transactional retries handle
concurrent conflicts.

## Consequences

- Ordering does not depend on temporary frontend state.
- Bulk creation and reordering operations must trigger synchronization.
- Concurrent conflicts are handled without turning the database constraint
  into the primary business rule.
