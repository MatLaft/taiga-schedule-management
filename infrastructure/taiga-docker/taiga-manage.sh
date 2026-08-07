#!/usr/bin/env sh

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#
# Copyright (c) 2021-present Kaleidos INC

set -x

if [ -f ".env" ]; then
  set -a
  # shellcheck disable=SC1091
  . ./.env
  set +a
fi

# Backward compatibility with old taiga-docker variable names.
export SECRET_KEY="${SECRET_KEY:-${TAIGA_SECRET_KEY:-insecure-secret-key-change-in-production}}"
export RABBITMQ_USER="${RABBITMQ_USER:-${TAIGA_ASYNC_RABBITMQ_USER:-${TAIGA_EVENTS_RABBITMQ_USER:-taiga}}}"
export RABBITMQ_PASS="${RABBITMQ_PASS:-${TAIGA_ASYNC_RABBITMQ_PASS:-${TAIGA_EVENTS_RABBITMQ_PASS:-taiga}}}"
export RABBITMQ_VHOST="${RABBITMQ_VHOST:-${TAIGA_ASYNC_RABBITMQ_VHOST:-${TAIGA_EVENTS_RABBITMQ_VHOST:-taiga}}}"
export EMAIL_BACKEND="${EMAIL_BACKEND:-console}"
export EMAIL_DEFAULT_FROM="${EMAIL_DEFAULT_FROM:-changeme@example.com}"
export EMAIL_USE_TLS="${EMAIL_USE_TLS:-False}"
export EMAIL_USE_SSL="${EMAIL_USE_SSL:-False}"
export EMAIL_HOST="${EMAIL_HOST:-smtp.host.example.com}"
export EMAIL_PORT="${EMAIL_PORT:-587}"
export EMAIL_HOST_USER="${EMAIL_HOST_USER:-user}"
export EMAIL_HOST_PASSWORD="${EMAIL_HOST_PASSWORD:-password}"
export ENABLE_TELEMETRY="${ENABLE_TELEMETRY:-False}"
export ATTACHMENTS_MAX_AGE="${ATTACHMENTS_MAX_AGE:-360}"

exec docker compose -f docker-compose.yml -f docker-compose-inits.yml run --rm taiga-manage $@
