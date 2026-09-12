#!/usr/bin/env bash
# Verifies all systemd user services of a deployed stack are stable.
# Expected units are written to /etc/nps-test/expected-units at build time.
set -uo pipefail

export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/1000}"

# Assemble a usable PATH for the su session.
export PATH="${HOME}/.nix-profile/bin:/run/current-system/sw/bin:/nix/var/nix/profiles/default/bin:/usr/bin:/bin:${PATH:-}"

EXPECTED_UNITS_FILE="/etc/nps-test/expected-units"
WAIT_TIMEOUT=300
STABILITY_GRACE=60

log() { printf '[%s] %s\n' "$(date '+%H:%M:%S')" "$*"; }
fail() {
  log "FAIL: $*"
  exit 1
}

wait_for_unit() {
  local unit="$1"
  local expected_substate="${2:-running}"
  local timeout="${3:-$WAIT_TIMEOUT}"

  log "waiting up to ${timeout}s for ${unit} (${expected_substate})"
  # shellcheck disable=SC2016
  timeout "$timeout" bash -c '
    while :; do
      state="$(systemctl --user show -p ActiveState --value "$1")"
      substate="$(systemctl --user show -p SubState --value "$1")"
      [ -n "$state" ] || { echo "unit $1 does not exist" >&2; exit 1; }
      [ "$state" = "active" ] && [ "$substate" = "$2" ] && exit 0
      [ "$state" = "failed" ] && { echo "unit $1 reached failed state" >&2; exit 1; }
      sleep 5
    done
  ' _ "$unit" "$expected_substate" || {
    log "=== ${unit} did not become active (${expected_substate}) within ${timeout}s ==="
    systemctl --user status "$unit" --no-pager || true
    journalctl --user -u "$unit" -n 200 --no-pager || true
    fail "unit ${unit} not active (${expected_substate})"
  }
  log "unit ${unit} is active (${expected_substate})"
}

[ -f "$EXPECTED_UNITS_FILE" ] || fail "expected units file ${EXPECTED_UNITS_FILE} does not exist"

mapfile -t UNITS < "$EXPECTED_UNITS_FILE"
[ "${#UNITS[@]}" -gt 0 ] || fail "no expected units in ${EXPECTED_UNITS_FILE}"

log "checking ${#UNITS[@]} unit(s): $(printf '%s ' "${UNITS[@]}")"

for unit in "${UNITS[@]}"; do
  wait_for_unit "$unit"
done

# Log the active storage driver and network backend.
log "podman storage driver: $(podman info --format '{{.Store.GraphDriverName}}')"
log "podman network backend: $(podman info --format '{{.Host.NetworkBackend}}')"

# Snapshot NRestarts baseline (a unit may restart once during startup).
declare -A BASELINE_RESTARTS
for unit in "${UNITS[@]}"; do
  BASELINE_RESTARTS["$unit"]="$(systemctl --user show -p NRestarts --value "$unit")"
done

# Re-check: must still be active, running, no new restarts.
sleep "$STABILITY_GRACE"
for unit in "${UNITS[@]}"; do
  substate="$(systemctl --user show -p SubState --value "$unit")"
  state="$(systemctl --user show -p ActiveState --value "$unit")"
  restarts="$(systemctl --user show -p NRestarts --value "$unit")"
  baseline="${BASELINE_RESTARTS["$unit"]}"
  if [ "$state" != "active" ] || [ "$substate" != "running" ] || [ "$restarts" != "$baseline" ]; then
    log "=== unit ${unit} is not stable after ${STABILITY_GRACE}s grace period ==="
    systemctl --user status "$unit" --no-pager || true
    journalctl --user -u "$unit" -n 200 --no-pager || true
    cname="${unit#podman-}"
    cname="${cname%.service}"
    podman logs "$cname" --tail 200 || true
    fail "unit ${unit} not stable after grace period (state=${state}, substate=${substate}, restarts=${restarts}, baseline=${baseline})"
  fi
  log "unit ${unit} stable: active (running), ${restarts} restarts"
done

log "SUCCESS: all ${#UNITS[@]} unit(s) of the stack are running"
