#!/bin/bash

set -euo pipefail

readonly SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
readonly BASE_PATH=$(cd "$SCRIPT_DIR/../.." && pwd)

readonly TARGET_PORTS=(5173 23333 24444)

log() {
  printf '[cleanup] %s\n' "$1"
}

pid_exists() {
  local pid="$1"
  [[ -n "$pid" && -d "/proc/$pid" ]]
}

is_project_pid() {
  local pid="$1"
  local cmdline=""
  local cwd=""

  if ! pid_exists "$pid"; then
    return 1
  fi

  cmdline=$(tr '\0' ' ' < "/proc/$pid/cmdline" 2>/dev/null || true)
  cwd=$(readlink -f "/proc/$pid/cwd" 2>/dev/null || true)

  if [[ -n "$cmdline" && "$cmdline" == *"$BASE_PATH"* ]]; then
    return 0
  fi

  if [[ -n "$cwd" && "$cwd" == "$BASE_PATH"* ]]; then
    return 0
  fi

  return 1
}

kill_pid_if_project_owned() {
  local pid="$1"
  if ! pid_exists "$pid"; then
    return
  fi

  if is_project_pid "$pid"; then
    kill -TERM "$pid" 2>/dev/null || true
    sleep 0.2
    if pid_exists "$pid"; then
      kill -KILL "$pid" 2>/dev/null || true
    fi
    log "killed pid=$pid"
  else
    log "skip pid=$pid (not owned by this project)"
  fi
}

kill_ports() {
  for port in "${TARGET_PORTS[@]}"; do
    local lines
    lines=$(ss -lntp 2>/dev/null | grep -E ":${port}\\b" || true)
    if [[ -z "$lines" ]]; then
      log "port $port is free"
      continue
    fi

    log "port $port is occupied, checking owner"
    while IFS= read -r line; do
      local pids=()
      mapfile -t pids < <(grep -oE 'pid=[0-9]+' <<< "$line" | cut -d= -f2 | sort -u)
      if [[ "${#pids[@]}" -eq 0 ]]; then
        continue
      fi
      for pid in "${pids[@]}"; do
        kill_pid_if_project_owned "$pid"
      done
    done <<< "$lines"
  done
}

kill_by_pattern() {
  local patterns=(
    "$BASE_PATH/daemon/node_modules/.bin/../nodemon/bin/nodemon.js"
    "$BASE_PATH/panel/node_modules/.bin/../nodemon/bin/nodemon.js"
    "$BASE_PATH/daemon/production/app.js"
    "$BASE_PATH/panel/production/app.js"
    "vite --host"
  )

  for pattern in "${patterns[@]}"; do
    local pids=()
    mapfile -t pids < <(pgrep -f "$pattern" || true)
    if [[ "${#pids[@]}" -eq 0 ]]; then
      continue
    fi
    for pid in "${pids[@]}"; do
      kill_pid_if_project_owned "$pid"
    done
  done
}

print_status() {
  local ports_regex
  ports_regex=$(IFS='|'; echo "${TARGET_PORTS[*]}")
  log "remaining listeners on target ports:"
  ss -lntp 2>/dev/null | grep -E ":(${ports_regex})\\b" || true
}

log "base path: $BASE_PATH"
log "step 1/2: kill project processes by pattern"
kill_by_pattern

log "step 2/2: free target ports if occupied"
kill_ports

print_status
log "done"
