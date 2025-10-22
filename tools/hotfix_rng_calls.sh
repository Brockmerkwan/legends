#!/usr/bin/env bash
set -euo pipefail
f="legends.sh"
cp "$f" "$f.bak.$(date +%Y%m%d_%H%M%S)"

# Replace invalid arithmetic function calls with command substitution
#   BEFORE: $(( d 6 + STR/2 ))
#   AFTER : $(( $(d 6) + STR/2 ))
sed -E -i '' \
  -e 's/\(\(\s*d\s+6\s+\+/\(\( $(d 6) +/g' \
  -e 's/\(\(\s*d\s+4\s+\+/\(\( $(d 4) +/g' \
  "$f"

chmod +x "$f"
echo "✅ Patched RNG calls. Backup created: $f.bak.*"
