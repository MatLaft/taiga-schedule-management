# Case study

## Context

Taiga provides agile project management capabilities, but this project
required an integrated schedule view. The extension introduces two
complementary representations:

- an activity list designed for querying and configuration;
- a Gantt chart designed for temporal planning and dependency management.

The main challenge was introducing these capabilities without breaking
existing workflows while maintaining consistency across three codebases built
with different technologies.

## Problem

Taiga activities were distributed across epics, user stories, and tasks. The
project needed to present them in a single hierarchy, persist dates and
positions, support activity dependencies, and control who could modify each
part of the schedule.

## Technical constraints

- an existing Django and Django REST Framework backend;
- a primary legacy frontend built with AngularJS, CoffeeScript, Jade, and SCSS;
- navigation partially migrated to Angular;
- multiple entity types sharing the same schedule representation;
- reliable permission enforcement even when the client state is stale;
- date changes capable of affecting multiple related activities.

## Solution

### Unified model

A Schedule model associates scheduling data with a project, an entity type,
and an entity identifier. Gantt ordering is persisted separately and protected
by a unique database constraint.

### Two complementary views

The activity list provides search, filters, sorting, and column configuration.
The Gantt chart displays the hierarchy over time and supports bar editing,
dependencies, item reordering, and critical path highlighting.

### Server-side business rules

Sensitive operations do not rely solely on interface controls. The backend
validates permissions for dates, dependencies, colors, and ordering, rejecting
unauthorized requests.

### Consistency and concurrency

Related changes are handled as backend business rules. Ordering operations use
transactions and retries to handle concurrent conflicts, while dependencies
can propagate date changes across connected activities.

## Relevant decisions

- [Schedule data model](decisions/001-schedule-data-model.md)
- [Server-side permission enforcement](decisions/002-permission-enforcement.md)
- [Gantt ordering](decisions/003-gantt-ordering.md)

## Outcome

The project integrates the activity list and Gantt chart as a single
configurable module while retaining separate viewing and modification
permissions. The same scheduling information can be inspected in the list and
manipulated visually in the Gantt chart, with persistence and validation
handled by the backend.

## Visual evidence

Screenshots and demo media will be added under `portfolio/`. Naming
conventions are documented in the
[portfolio assets guide](../portfolio/README.md).

## Key learnings

- Authorization rules must be enforced by the server even when the interface
  already hides restricted operations.
- Cross-cutting features require explicit contracts between components.
- Persistent ordering requires deliberate concurrency handling.
- Complex functionality can be introduced into a legacy interface when its
  responsibilities are separated into verifiable units.
