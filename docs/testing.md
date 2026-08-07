# Testing

## Repository validation

Check the shell script syntax:

```bash
bash -n scripts/setup.sh
bash -n scripts/start.sh
bash -n scripts/build-front-next.sh
bash -n scripts/test.sh
```

Validate the Docker configuration:

```bash
docker compose \
  --env-file .env.example \
  -f infrastructure/taiga-docker/docker-compose.yml \
  -f infrastructure/taiga-docker/docker-compose.local.yml \
  config
```

## Focused backend tests

Prepare the backend Python environment and run:

```bash
cd components/taiga-back
./.venv/bin/pytest \
  tests/integration/test_schedule_inline_write_permissions.py \
  tests/integration/test_schedule_bulk_apply_dates.py \
  tests/integration/test_schedule_dependencies.py \
  tests/integration/test_bulk_create_api_reorder.py \
  -q
```

The following shortcut runs the same suite when
`components/taiga-back/.venv` is available:

```bash
./scripts/test.sh
```

## Scope

Each component retains its own test suite in its independent repository. The
root CI validates repository integration and structure; backend- and
frontend-specific pipelines should remain with their corresponding components.
