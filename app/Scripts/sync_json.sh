#!/bin/bash
# Copies photoset JSON files from CULLEN_JSON_SOURCE into the app bundle
# and regenerates index.json.
set -euo pipefail

SOURCE="${CULLEN_JSON_SOURCE}"
DEST="${BUILT_PRODUCTS_DIR}/${CONTENTS_FOLDER_PATH}"

if [ ! -d "$SOURCE" ]; then
  echo "warning: CULLEN_JSON_SOURCE not found: ${SOURCE}"
  exit 0
fi

# Copy all photoset JSON files (skip index — it's regenerated below)
find "$SOURCE" -maxdepth 1 -name '*.json' ! -name 'index.json' -exec cp -f {} "$DEST/" \;

# Regenerate index.json as a sorted JSON array of filenames
python3 - "$SOURCE" "$DEST/index.json" << 'EOF'
import sys, os, json

src, out = sys.argv[1], sys.argv[2]
names = sorted(f for f in os.listdir(src) if f.endswith('.json') and f != 'index.json')
with open(out, 'w') as f:
    json.dump(names, f)
EOF
