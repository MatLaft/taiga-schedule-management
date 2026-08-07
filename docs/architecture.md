# Architecture

## Components

### Backend

`components/taiga-back` contains the Django/DRF backend. It is responsible for:

- schedule data persistence;
- dependency and schedule-item update APIs;
- chronological consistency rules;
- permission enforcement;
- entity ordering and synchronization.

Reference files:

- `taiga/projects/schedule/services.py`
- `taiga/projects/schedule/api.py`
- `taiga/projects/schedule/signals.py`
- the epic, user story, and task APIs.

### Legacy frontend

`components/taiga-front` contains the primary interface built with AngularJS,
CoffeeScript, Jade, and SCSS. It includes:

- the activity list;
- the Gantt chart;
- visual editing and dependency management;
- critical path and slack calculation;
- permission controls and module configuration.

The main Gantt controller is located at
`app/coffee/modules/gantt.coffee`.

### Modern frontend

`components/taiga-front-next` provides the Angular shell and project
navigation. Its role in this module is focused on navigation and the visual
availability of the Schedule and Gantt routes.

### Infrastructure

`infrastructure/taiga-docker` contains Docker Compose, the gateway, and local
configuration. Compose files reference the components through the
`../../components/` path.

## Data flow

1. The user opens the activity list or Gantt chart through Angular navigation.
2. The legacy frontend retrieves entities and schedule data through REST.
3. The interface submits only the requested operation.
4. The backend validates the project, entity, chronological rules, and
   permissions.
5. The change is persisted in PostgreSQL.
6. The interface refreshes the related views.

## Relevant contracts

- Embedded schedule data uses `include_schedule=true`.
- Dedicated item updates use the `schedule-items-update` contract.
- Dependencies use the `schedule-dependencies` resource.
- Bulk date changes use `bulk_apply_dates`.
- User stories are identified as `userstory` in the schedule contract.

## Permissions

Viewing:

- `view_schedule`
- `view_gantt`

Modification:

- `modify_schedule_links`
- `modify_schedule_dates`
- `modify_schedule_color`
- `modify_gantt_list_order`

Permissions guide the interface, but the final authorization decision is
enforced by the backend.
