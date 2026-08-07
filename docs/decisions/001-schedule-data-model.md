# ADR 001: Unified schedule data model

- Status: accepted
- Context: epics, user stories, and tasks must participate in the same
  schedule.

## Decision

Represent schedule data by project, entity type, and entity identifier while
maintaining ordering in a dedicated structure.

## Consequences

- The API can handle different entity types through a shared contract.
- The frontend must explicitly map its entity types to the values accepted by
  the schedule API.
- The backend must synchronize integrity between the source entity and its
  schedule data.
