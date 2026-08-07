# Critical path

The Gantt chart calculates and highlights the critical path by considering leaf
activities and the project completion milestone.

The current implementation:

- includes activities without children when building the graph;
- identifies activities with the latest due date as completion milestones;
- considers paths that reach a completion node;
- highlights the candidate path with the lowest total slack;
- displays slack on hover while critical-path highlighting is active.

A visual example will be added later at
`portfolio/screenshots/critical-path.png`.
