# Permissions

The activity list and Gantt chart share the same module activation setting but
have separate viewing permissions. Modification operations are controlled
individually.

| Permission | Capability |
| --- | --- |
| `view_schedule` | View the activity list |
| `view_gantt` | View the Gantt chart |
| `modify_schedule_links` | Create or remove dependencies |
| `modify_schedule_dates` | Change dates |
| `modify_schedule_color` | Change colors |
| `modify_gantt_list_order` | Reorder Gantt items |

The backend repeats these checks to prevent unauthorized writes when the
interface state is stale.

A visual example will be added later at
`portfolio/screenshots/permissions.png`.
