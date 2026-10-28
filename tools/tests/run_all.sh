#!/usr/bin/env bash
# Runs every tools/tests/test_*.gd headless and fails if any test:
#   exits non-zero (a FAIL check), crashes, hangs past the time limit,
#   or prints a FAIL / ERROR / SCRIPT ERROR / Parse Error line.
# Usage (from the repo root): tools/tests/run_all.sh [path-to-godot] [test-name-filter]
set -u
GODOT="${1:-godot}"
FILTER="${2:-}"
LIMIT="${TEST_TIME_LIMIT:-300}"
failed=()
for t in tools/tests/test_*.gd; do
  name="$(basename "$t" .gd)"
  [[ -n "$FILTER" && "$name" != *"$FILTER"* ]] && continue
  log="$(mktemp)"
  timeout "$LIMIT" "$GODOT" --headless --script "$t" >"$log" 2>&1
  code=$?
  bad="$(grep -E '^FAIL|SCRIPT ERROR|Parse Error|^ERROR' "$log" | head -20)"
  summary="$(grep -E '^RESULT' "$log" | tail -1)"
  if [[ $code -ne 0 || -n "$bad" || -z "$summary" ]]; then
    [[ $code -eq 124 ]] && bad="timed out after ${LIMIT}s"$'\n'"$bad"
    [[ -z "$summary" && $code -ne 124 ]] && bad="never reached C.done() (exit $code)"$'\n'"$bad"
    echo "✗ $name"
    echo "$bad" | sed 's/^/    /'
    failed+=("$name")
  else
    echo "✓ $name  ${summary#RESULT: }"
  fi
  rm -f "$log"
done
if [[ ${#failed[@]} -gt 0 ]]; then
  echo "${#failed[@]} test(s) failed: ${failed[*]}"
  exit 1
fi
echo "All tests passed."
