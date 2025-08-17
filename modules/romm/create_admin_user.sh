#!/usr/bin/env bash
set -euo pipefail

USERNAME="${ADMIN_USERNAME:-admin}"
PASSWORD="${ADMIN_PASSWORD:-admin}"
EMAIL="${ADMIN_EMAIL:-admin@example.com}"

curl -s -c /tmp/romm_cookies http://localhost:8080/api/heartbeat > /dev/null
CSRF_TOKEN=$(grep romm_csrftoken /tmp/romm_cookies | cut -f7)

curl -X POST http://localhost:8080/api/users \
  -b /tmp/romm_cookies \
  -H "Content-Type: application/json" \
  -H "X-CSRFToken: $CSRF_TOKEN" \
  -d "{
    \"username\": \"$USERNAME\",
    \"password\": \"$PASSWORD\",
    \"email\": \"$EMAIL\",
    \"role\": \"admin\"
  }"

rm /tmp/romm_cookies