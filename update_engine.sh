#!/bin/bash
# Auto-update tapjunkie_engine dependency in all pubspec.yaml files

ROOT_DIR="$HOME/cube23"
SEARCH_PATTERN="pubspec.yaml"

echo "🔍 Scanning for pubspec.yaml files in $ROOT_DIR ..."
echo ""

find "$ROOT_DIR" -type f -name "$SEARCH_PATTERN" | while read -r FILE; do
    echo "📌 Updating: $FILE"

    # Backup
    cp "$FILE" "$FILE.bak"

    # Remove old tapjunkie_engine block
    sed -i '/tapjunkie_engine:/,/git:/d' "$FILE"

    # Insert new block at end of dependencies:
    sed -i '/^dependencies:/a\
  tapjunkie_engine:\n\
    git:\n\
      url: https://github.com/${GITHUB_ACTOR}:${GITHUB_TOKEN}@github.com/Sinhuej/tapjunkie_engine.git' "$FILE"

    echo "✔ Updated and backed up as $FILE.bak"
    echo ""
done

echo "🎉 All pubspec.yaml files updated successfully!"

