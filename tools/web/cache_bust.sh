#!/usr/bin/env bash
# Gives every build its own file addresses (index.js?v=<version>, index.pck?v=…, index.wasm?v=…)
# so a host or browser cache can never hand players an old game file after a deploy.
# SiteGround's front cache ignores .htaccess cache rules, so this is what actually works.
# Usage: tools/web/cache_bust.sh build/web <version>
set -euo pipefail
DIR="$1"
V="$2"

swap() {   # swap FILE OLD NEW: replace OLD with NEW, and fail if OLD isn't there
  local file="$1" old="$2" new="$3"
  if ! grep -qF -- "$old" "$file"; then
    echo "::error::cache_bust: '$old' not found in $file (did the Godot web template change?)"
    exit 1
  fi
  OLD="$old" NEW="$new" perl -0pi -e 's/\Q$ENV{OLD}\E/$ENV{NEW}/g' "$file"
}

swap "$DIR/index.html" 'src="index.js"' "src=\"index.js?v=$V\""
swap "$DIR/index.js" '`${loadPath}.wasm`' "\`\${loadPath}.wasm?v=$V\`"
swap "$DIR/index.js" '`${loadPath}.audio.worklet.js`' "\`\${loadPath}.audio.worklet.js?v=$V\`"
swap "$DIR/index.js" 'this.preloadFile(pack, pack)' "this.preloadFile(pack + '?v=$V', pack)"
echo "Cache-busted build files with v=$V"
