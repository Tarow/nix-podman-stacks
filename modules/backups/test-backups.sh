#!/usr/bin/env bash
# Test script for nix-podman-stacks restic backups.
#
# Discovers and runs all restic backup services defined in the current
# home-manager generation.  For each service, it:
#   1. Runs the backup and waits for completion
#   2. Reports exit status, duration, files processed
#   3. Shows the latest snapshot summary
#   4. Lists all stored snapshots for that repository
#
# Usage:
#   test-backups.sh                    # run everything
#   test-backups.sh [name ...]         # run specific service(s)
#   test-backups.sh -l | --list        # list available services
#   test-backups.sh -h | --help        # this message
#
# Examples:
#   test-backups.sh                    # run global + all split backups
#   test-backups.sh global             # just the global backup
#   test-backups.sh baikal paperless   # specific split backups
#
# shellcheck disable=SC2311,SC2312
set -euo pipefail

# ── Colors ──────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

ok()   { echo -e "${GREEN}✓${NC} $*"; }
info() { echo -e "${CYAN}▸${NC} $*"; }
warn() { echo -e "${YELLOW}⚠${NC} $*"; }
fail() { echo -e "${RED}✗${NC} $*"; }
header() { echo -e "\n${BOLD}═══ $* ═══${NC}"; }

# ── Helpers ─────────────────────────────────────────────────────────

# Parse a systemd service file for Environment=KEY=value lines.
read_env_from_service() {
  local svc="$1" key="$2"
  grep -oP "(?<=^Environment=${key}=).*" "${svc}" 2>/dev/null || true
}

# Discover available backup services by scanning unit-file paths.
discover_services() {
  local units
  units=$(systemctl --user list-unit-files --no-legend 2>/dev/null \
    | awk '/^restic-backups-[^.]+\.service/ {print $1}')
  if [[ -z "${units}" ]]; then
    return
  fi
  # Strip .service suffix, return sorted
  printf '%s\n' "${units[@]}" | sed 's/\.service$//' | sort
}

# Locate the unit file path for a service name.
unit_path() {
  local name="$1"
  systemctl --user show -p FragmentPath "${name}.service" --value 2>/dev/null \
    || echo "${HOME}/.config/systemd/user/${name}.service"
}

# Run a single backup service and report results.
run_backup() {
  local name="$1"
  local svc="${name}.service"
  local rc=0

  # Locate unit file
  local unit
  unit=$(unit_path "${name}")
  if [[ ! -f "${unit}" ]]; then
    fail "Service unit not found: ${unit}"
    return 1
  fi

  # Extract metadata from the service file
  local repo password_file
  repo=$(read_env_from_service "${unit}" "RESTIC_REPOSITORY")   || repo=""
  password_file=$(read_env_from_service "${unit}" "RESTIC_PASSWORD_FILE") || password_file=""

  echo ""
  echo -e "  ${BOLD}Service:${NC}   ${name}"
  echo -e "  ${BOLD}Repo:${NC}      ${repo:-<not set>}"
  if [[ -n "${password_file}" && -f "${password_file}" ]]; then
    echo -e "  ${BOLD}Password:${NC}  ${password_file} ${GREEN}(exists)${NC}"
  elif [[ -n "${password_file}" ]]; then
    echo -e "  ${BOLD}Password:${NC}  ${password_file} ${RED}(missing!)${NC}"
  fi

  # ── Run the backup ──────────────────────────────────────────────
  local start_time end_time duration rendered
  start_time=$(date +%s)

  echo ""
  echo -e "  ${YELLOW}Starting backup...${NC}"
  if ! systemctl --user start "${svc}" 2>&1; then
    # If start failed immediately, capture the error
    end_time=$(date +%s)
    duration=$(( end_time - start_time ))
    duration="${duration}s"
    rc=1
  else
    # Wait for the oneshot to finish
    local state
    for _ in $(seq 1 60); do
      state=$(systemctl --user show -p ActiveState --value "${svc}" 2>/dev/null || echo "inactive")
      if [[ "${state}" != "activating" && "${state}" != "active" ]]; then
        break
      fi
      sleep 1
    done

    end_time=$(date +%s)
    duration=$(( end_time - start_time ))
    duration="${duration}s"

    # Collect exit status
    rc=$(systemctl --user show -p ExecMainStatus --value "${svc}" 2>/dev/null || echo 0)
    if [[ -z "${rc}" ]]; then
      rc=0
    fi
  fi

  if [[ "${rc}" -eq 0 ]]; then
    ok "Backup completed in ${duration}"
  else
    fail "Backup failed (exit ${rc}) after ${duration}"
  fi

  # ── Journal excerpt ─────────────────────────────────────────────
  echo ""
  echo -e "  ${BOLD}Last run log:${NC}"
  local last_line
  last_line=$(journalctl --user -u "${svc}" --no-pager -n 1 --output=short-iso 2>/dev/null || true)
  if [[ -n "${last_line}" ]]; then
    # Show the last few informative lines
    journalctl --user -u "${svc}" --no-pager -n 20 --output=cat 2>/dev/null \
      | grep -E 'Files:|Dirs:|snapshot|processed|error|FAIL|backend' \
      | sed 's/^/    /'
  else
    warn "No journal entries found for ${svc}"
  fi

  # ── Snapshot info (if we have repo access) ──────────────────────
  if [[ -n "${repo}" && -n "${password_file}" && -f "${password_file}" ]]; then
    local restic_bin
    # Extract restic binary path from ExecStart in the unit file
    restic_bin=$(grep -oP "(?<=/nix/store/)[^/]+/bin/restic(?=[ \'])" "${unit}" 2>/dev/null || true)
    if [[ -z "${restic_bin}" ]]; then
      # Fallback: try to find it in PATH or nix store
      restic_bin=$(command -v restic 2>/dev/null || find /nix/store -maxdepth 5 -name restic -type f -path '*/bin/restic' 2>/dev/null | head -1)
    else
      restic_bin="/nix/store/${restic_bin}"
    fi

    if [[ -x "${restic_bin}" ]]; then
      local pw
      pw=$(<"${password_file}")

      echo ""
      echo -e "  ${BOLD}Snapshots:${NC}"

      # Latest snapshot summary
      local ls_out
      ls_out=$(RESTIC_PASSWORD="${pw}" "${restic_bin}" -r "${repo}" snapshots --latest 1 2>/dev/null || true)
      if [[ -n "${ls_out}" ]]; then
        echo "${ls_out}" \
          | grep -v '^repository\|^password\|^$\|^----\|[0-9] snapshots' \
          | sed 's/^/    /'
      else
        warn "Could not query repository snapshots"
      fi

      # Snapshot count
      local snap_count
      snap_count=$(RESTIC_PASSWORD="${pw}" "${restic_bin}" -r "${repo}" snapshots 2>/dev/null \
                    | grep -cE '^[a-f0-9]{8}\s' || true)
      echo "    Total snapshots: ${snap_count:-0}"
    else
      warn "Could not locate restic binary"
    fi
  fi

  echo ""
  return "${rc}"
}

# ── Main ────────────────────────────────────────────────────────────

list_services() {
  local services
  services=$(discover_services)
  if [[ -z "${services}" ]]; then
    warn "No restic backup services found."
    return
  fi
  echo "Available backup services:"
  while IFS= read -r svc; do
    local state last
    state=$(systemctl --user show -p ActiveState --value "${svc}.service" 2>/dev/null || echo "unknown")
    last=$(systemctl --user show -p ExecMainStatus --value "${svc}.service" 2>/dev/null || echo "-")
    echo "  ${svc}  (active state: ${state}, last exit: ${last})"
  done <<< "${services}"
}

print_usage() {
  sed -n '/^# Usage:/,/^#*$/p' "$0" \
    | sed 's/^# //;s/^#$//' \
    | head -n -1
}

main() {
  local services

  case "${1:-}" in
    -h|--help)
      print_usage
      exit 0
      ;;
    -l|--list)
      list_services
      exit 0
      ;;
    "")
      services=$(discover_services)
      if [[ -z "${services}" ]]; then
        warn "No restic backup services found."
        warn "Is the backup module enabled in your home-manager config?"
        exit 1
      fi
      mapfile -t svc_list <<< "${services}"
      ;;
    *)
      svc_list=("$@")
      # Validate that requested services exist
      local known
      known=$(discover_services)
      for arg in "${svc_list[@]}"; do
        local full_name="restic-backups-${arg}"
        if ! grep -q "^${full_name}$" <<< "${known}" 2>/dev/null; then
          # Try as-is (maybe user passed full name like restic-backups-global)
          if ! grep -q "^restic-backups-${arg}$" <<< "${known}" 2>/dev/null \
             && ! grep -q "^${arg}$" <<< "${known}" 2>/dev/null; then
            warn "Unknown service: ${arg}. Use -l to list available services."
            exit 1
          fi
        fi
      done
      ;;
  esac

  # Normalize names: accept "global" or "restic-backups-global"
  local normalized=()
  for svc in "${svc_list[@]}"; do
    if [[ "${svc}" == restic-backups-* ]]; then
      normalized+=("${svc}")
    else
      normalized+=("restic-backups-${svc}")
    fi
  done

  local total=${#normalized[@]}
  local pass=0 fail_count=0

  header "Testing ${total} backup service(s)"

  for svc in "${normalized[@]}"; do
    header "${svc}"
    if run_backup "${svc}"; then
      ((pass++)) || true
    else
      ((fail_count++)) || true
    fi
  done

  # ── Summary ─────────────────────────────────────────────────────
  echo ""
  header "Summary"
  echo ""
  echo -e "  Total:  ${total}"
  echo -e "  Passed: ${GREEN}${pass}${NC}"
  if [[ "${fail_count}" -gt 0 ]]; then
    echo -e "  Failed: ${RED}${fail_count}${NC}"
  fi
  echo ""

  if [[ "${fail_count}" -gt 0 ]]; then
    exit 1
  fi
}

main "$@"
